from flask import Flask, request, jsonify
import mysql.connector
from flask_cors import CORS
from datetime import datetime, timedelta, timezone
from dateutil.relativedelta import relativedelta
import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging
from notification import send_notification
from apscheduler.schedulers.background import BackgroundScheduler

app = Flask(__name__)
CORS(app)

# ---------------------------------------------------------------------------------------------
# APP
# ---------------------------------------------------------------------------------------------
@app.route('/')
def home():
    return {
        "status": "success",
        "message": "MyMarsaid API Running"
    }
# =========================
# KONEKSI DATABASE
# =========================

import os

db = mysql.connector.connect(
    host=os.getenv("MYSQLHOST"),
    user=os.getenv("MYSQLUSER"),
    password=os.getenv("MYSQLPASSWORD"),
    database=os.getenv("MYSQLDATABASE"),
    port=int(os.getenv("MYSQLPORT"))
)

# =========================
# FIREBASE
# =========================
import os

firebase_key = os.getenv(
    "FIREBASE_KEY_PATH",
    "/etc/secrets/serviceAccountKey.json"
)

cred = credentials.Certificate(firebase_key)

firebase_admin.initialize_app(cred)

# =========================
# LOGIN
# =========================

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get("username")
    password = data.get("password")
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT
            id,
            username,
            password,
            role,
            id_warga
        FROM users
        WHERE username = %s
    """, (username,))

    user = cursor.fetchone()

    # Username tidak ditemukan
    if user is None:
        return jsonify({
            "status": "error",
            "message": "Username atau password salah"
        }), 401

    # Password salah
    if user["password"] != password:
        return jsonify({
            "status": "error",
            "message": "Username atau password salah"
        }), 401

    # Akun warga belum terhubung
    if user["role"] == "warga" and user["id_warga"] is None:
        return jsonify({
            "status": "error",
            "message": "Akun belum terhubung"
        }), 400

    return jsonify({
        "status": "success",
        "message": "Login berhasil",
        "user": {
            "id": user["id"],
            "username": user["username"],
            "role": user["role"],
            "id_warga": user["id_warga"]
        }
    })

# =========================
# SAVE FCM TOKEN
# =========================
@app.route('/save_fcm_token', methods=['POST'])
def save_fcm_token():

    data = request.get_json()

    id_user = data.get("id") or data.get("id_user")
    token = data.get("token") or data.get("fcm_token")

    if not id_user or not token:
        return jsonify({
            "status": "error",
            "message": "Data tidak lengkap"
        }), 400

    cursor = db.cursor()

    cursor.execute("""
        UPDATE users
        SET fcm_token = NULL
        WHERE fcm_token = %s
    """, (token,))

    cursor.execute("""
        UPDATE users
        SET fcm_token = %s
        WHERE id = %s
    """, (token, id_user))

    db.commit()
    cursor.close()

    print("TOKEN BERHASIL DISIMPAN")

    return jsonify({
        "status": "success",
        "message": "FCM Token berhasil disimpan"
    })


# =========================
# IMPORT RULE ENGINE
# =========================
from rule_notification import (
    get_kategori,
    hitung_telat,
    cek_jadwal,
    cek_setelah_jatuh_tempo,
    cek_awal_bulan,
    sudah_lunas
)

from notification import send_notification


# =========================
# TEST PUSH NOTIFICATION
# =========================
@app.route('/send_test_notification/<int:id_user>')
def send_test_notification(id_user):

    success = send_notification(
        db,
        id_user,
        "Test Notifikasi 🔔",
        "Notifikasi berhasil dikirim."
    )

    if success:
        return jsonify({"status": "success"})

    return jsonify({"status": "error"})


# =========================
# RULE NOTIFICATION
# =========================
def cek_notifikasi():

    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            users.id,
            warga.nama,
            rumah.id_rumah
        FROM users
        JOIN warga
            ON users.id_warga = warga.id_warga
        JOIN rumah
            ON warga.id_warga = rumah.id_warga
        WHERE users.role = 'warga'
    """)

    data = cursor.fetchall()

    for warga in data:

        # Hitung jumlah keterlambatan
        jumlah_telat = hitung_telat(
            cursor,
            warga["id_rumah"]
        )

        # Tentukan kategori
        kategori = get_kategori(jumlah_telat)

        # Default status
        status = "Tidak dikirim"

        # =========================
        # CEK AWAL BULAN
        # =========================
        if cek_awal_bulan():

            success = send_notification(
                db,
                warga["id"],
                "Pengingat Iuran Bulanan",
                f"Halo {warga['nama']}, periode pembayaran iuran bulan ini telah dibuka. Saatnya melakukan pembayaran."
            )

            if success:
                status = "Dikirim (Awal Bulan)"
            else:
                status = "Gagal (Token Tidak Ada)"

        # =========================
        # CEK JADWAL SESUAI KATEGORI
        # =========================
        elif cek_jadwal(kategori):

            success = send_notification(
                db,
                warga["id"],
                "Pengingat Iuran",
                f"Halo {warga['nama']}, kami mengingatkan untuk melakukan pembayaran iuran bulan ini sesuai jadwal. Terima kasih."
            )

            if success:
                status = "Dikirim (Sesuai Kategori)"
            else:
                status = "Gagal (Token Tidak Ada)"

        # =========================
        # CEK SETELAH JATUH TEMPO
        # =========================
        elif cek_setelah_jatuh_tempo():

            if not sudah_lunas(cursor, warga["id_rumah"]):

                success = send_notification(
                    db,
                    warga["id"],
                    "Iuran Melewati Jatuh Tempo",
                    f"Halo {warga['nama']}, pembayaran iuran bulan ini belum dilakukan. Anda telah melewati batas pembayaran."
                )

                if success:
                    status = "Dikirim (Belum Lunas)"
                else:
                    status = "Gagal (Token Tidak Ada)"

            else:
                status = "Sudah Lunas (Tidak Dikirim)"

        # =========================
        # OUTPUT
        # =========================
        print(f"""
Nama           : {warga["nama"]}
ID Rumah       : {warga["id_rumah"]}
Jumlah Telat   : {jumlah_telat}
Kategori       : {kategori}
Status         : {status}
-----------------------------------------
""")

    cursor.close()


# =========================
# SCHEDULER TASK
# =========================
def run_notification_scheduler():

    print("Scheduler menjalankan pengecekan notifikasi...")

    cek_notifikasi()

# =========================
# BACKGROUND SCHEDULER
# =========================
scheduler = BackgroundScheduler()

scheduler.add_job(
    run_notification_scheduler,
    trigger="cron",
    hour=8,
    minute=0,
    id="notification_scheduler",
    replace_existing=True
)


# =========================
# TEST 
# =========================
@app.route('/test_rule')
def test_rule():

    cek_notifikasi()

    return jsonify({
        "status": "success",
        "message": "Rule Engine berhasil dijalankan."
    })
    
# ---------------------------------------------------------------------------------------------
# ADMIN
# ---------------------------------------------------------------------------------------------

# =========================
# DASHBOARD
# =========================

from datetime import datetime

@app.route('/dashboard', methods=['GET'])
def dashboard():

    cursor = db.cursor(dictionary=True)

    bulan_indonesia = [

        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"

    ]

    now = datetime.now()

    bulan = bulan_indonesia[
        now.month - 1
    ]

    tahun = now.year

    # =====================
    # TOTAL WARGA
    # =====================

    cursor.execute("""
                   
        SELECT COUNT(*) AS total_warga
                   
        FROM warga
                   
    """)

    total_warga = cursor.fetchone()

    # =====================
    # BELUM BAYAR
    # =====================

    cursor.execute("""
        SELECT COUNT(*) AS belum_bayar
                   
        FROM rumah r
                   
        WHERE r.id_rumah NOT IN (
                   
            SELECT id_rumah
            FROM iuran
            WHERE bulan = %s
            AND tahun = %s
            AND status = 'Lunas'
                   
        )

    """, (
        bulan,
        tahun
    ))

    belum_bayar = cursor.fetchone()

    # =====================
    # TOTAL IURAN
    # =====================

    cursor.execute("""
        SELECT
            IFNULL(
                SUM(total),
                0
            ) AS total_iuran

        FROM iuran
        WHERE
            bulan = %s
            AND tahun = %s
            AND status = 'Lunas'

    """, (

        bulan,
        tahun

    ))

    total_iuran = cursor.fetchone()
    data = {
        "bulan": bulan,
        "tahun": tahun,
        "total_warga":
            total_warga['total_warga'],

        "belum_bayar":
            belum_bayar['belum_bayar'],

        "total_iuran":
            total_iuran['total_iuran'],

        "total_pengumuman": 0
    }

    cursor.close()
    return jsonify(data)


# =========================
# GET DATA WARGA
# =========================
@app.route('/warga', methods=['GET'])
def get_warga():
    cursor = db.cursor(dictionary=True)

    query = """
    SELECT 
        warga.id_warga, 
        warga.nama, 
        warga.no_hp, 
        warga.status, 
        rumah.id_rumah, 
        rumah.no_rumah, 
        rumah.luas_tanah 
    FROM warga 
    LEFT JOIN rumah ON warga.id_warga = rumah.id_warga 
    ORDER BY rumah.no_rumah ASC
    """
    
    cursor.execute(query)
    data = cursor.fetchall()
    return jsonify(data)

# =========================
# DETAIL WARGA
# =========================
@app.route('/warga/<int:id>', methods=['GET'])
def detail_warga(id):
    cursor = db.cursor(dictionary=True)
    query = """

    SELECT
        warga.id_warga,
        warga.nama,
        warga.no_hp,
        warga.status,

        rumah.id_rumah,
        rumah.no_rumah,
        rumah.luas_tanah

    FROM warga
    LEFT JOIN rumah
    ON warga.id_warga = rumah.id_warga

    WHERE warga.id_warga = %s
    """
    cursor.execute(query, (id,))
    data = cursor.fetchone()

    if data:
        return jsonify(data)

    return jsonify({
        "message": "Data tidak ditemukan"
    }), 404

# =========================
# TAMBAH WARGA
# =========================

@app.route('/add_warga',
methods=['POST'])
def tambah_warga():
    data = request.json
    nama = data['nama']
    no_hp = data['no_hp']
    status = data['status']
    no_rumah = data['no_rumah']
    luas_tanah = data['luas_tanah']

    cursor = db.cursor()

    # INSERT WARGA
    query_warga = """
    INSERT INTO warga (
        nama,
        no_hp,
        status
    )
    VALUES (%s, %s, %s)
    """

    cursor.execute(
        query_warga,
        (
            nama,
            no_hp,
            status
        )
    )

    db.commit()

    # AMBIL ID TERAKHIR
    id_warga = cursor.lastrowid

    # INSERT RUMAH
    query_rumah = """
    INSERT INTO rumah (
        no_rumah,
        luas_tanah,
        id_warga
    )

    VALUES (%s, %s, %s)
    """

    cursor.execute(
        query_rumah,
        (
            no_rumah,
            luas_tanah,
            id_warga
        )
    )

    db.commit()

    return jsonify({
        "status": "success",

        "message":
            "Warga berhasil ditambahkan"
    })


# =========================
# EDIT WARGA
# =========================

@app.route('/edit_warga/<int:id>', methods=['PUT'])
def edit_warga(id):
    try:
        data = request.json
        
        nama = data.get('nama')
        no_hp = data.get('no_hp')
        status = data.get('status')
        no_rumah = data.get('no_rumah')
        luas_tanah = data.get('luas_tanah')

        cursor = db.cursor()

        query_warga = """UPDATE warga SET nama=%s, no_hp=%s, status=%s WHERE id_warga=%s"""
        cursor.execute(query_warga, (nama, no_hp, status, id))

        query_rumah = """UPDATE rumah SET no_rumah=%s, luas_tanah=%s WHERE id_warga=%s"""
        cursor.execute(query_rumah, (no_rumah, luas_tanah, id))

        db.commit()
        return jsonify({"status": "success", "message": "Data berhasil diperbarui"})

    except Exception as e:
        db.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500


# =========================
# HAPUS WARGA
# =========================
@app.route('/hapus_warga/<int:id>',
methods=['DELETE'])

def hapus_warga(id):
    cursor = db.cursor()

    query_rumah = """

    DELETE FROM rumah
    WHERE id_warga=%s

    """

    cursor.execute(
        query_rumah,
        (id,)
    )

    query_warga = """

    DELETE FROM warga
    WHERE id_warga=%s
    """

    cursor.execute(
        query_warga,
        (id,)
    )
    db.commit()

    return jsonify({
        "status": "success"
    })


# =========================
# KELOLA IURAN
# =========================

@app.route('/kelola_iuran', methods=['GET'])
def kelola_iuran():

    bulan = request.args.get('bulan')
    tahun = request.args.get('tahun')
    status = request.args.get('status', 'Semua')

    cursor = db.cursor(dictionary=True)

    query = """
    SELECT

        warga.id_warga,
        warga.nama,

        rumah.id_rumah,
        rumah.no_rumah,

        iuran.id_iuran,

        iuran.iuran,
        iuran.kas,
        iuran.kas_ibu,
        iuran.beras,

        iuran.total,

        COALESCE(iuran.status, 'Belum Bayar') AS status

    FROM warga

    JOIN rumah
        ON warga.id_warga = rumah.id_warga

    LEFT JOIN iuran
        ON rumah.id_rumah = iuran.id_rumah
        AND iuran.bulan = %s
        AND iuran.tahun = %s

    """

    params = [bulan, tahun]

    if status == "Lunas":
        query += """
        WHERE iuran.status = 'Lunas'
        """

    elif status == "Belum Bayar":
        query += """
        WHERE iuran.status = 'Belum Bayar'
           OR iuran.status IS NULL
        """

    query += """
    ORDER BY rumah.no_rumah ASC
    """

    cursor.execute(query, params)

    data = cursor.fetchall()

    return jsonify(data)


# =========================
# DETAIL IURAN
# =========================

@app.route('/detail_iuran/<int:id_rumah>', methods=['GET'])
def detail_iuran(id_rumah):

    bulan = request.args.get('bulan')
    tahun = request.args.get('tahun')

    cursor = db.cursor(dictionary=True)

    query = """

        SELECT

            id_iuran,

            iuran,
            kas,
            kas_ibu,
            beras,

            total,
            status,

            DATE_FORMAT(
                tanggal_bayar,
                '%Y-%m-%d'
            ) AS tanggal_bayar,

            bulan,
            tahun

        FROM iuran

        WHERE id_rumah = %s
        AND bulan = %s
        AND tahun = %s

    """

    cursor.execute(

        query,

        (
            id_rumah,
            bulan,
            tahun
        )

    )

    data = cursor.fetchone()

    cursor.close()

    # =========================
    # BELUM ADA PEMBAYARAN
    # =========================

    if data is None:
        return jsonify({
            "id_iuran": None,
            "iuran": 0,
            "kas": 0,
            "kas_ibu": 0,
            "beras": 0,
            "total": 0,
            "status": "Belum Bayar",
            "tanggal_bayar": None,
            "bulan": bulan,
            "tahun": tahun
        })

    return jsonify(data)


# =========================
# UPDATE / INSERT IURAN
# =========================

@app.route('/update_iuran',
methods=['POST'])

def update_iuran():

    data = request.json

    id_rumah = data['id_rumah']

    bulan = data['bulan']

    tahun = data['tahun']

    tanggal_bayar = data['tanggal_bayar']
    iuran = int(
        data.get('iuran', 0)
    )

    kas = int(
        data.get('kas', 0)
    )

    kas_ibu = int(
        data.get('kas_ibu', 0)
    )

    beras = int(
        data.get('beras', 0)
    )

    # TOTAL
    total = (
        iuran +
        kas +
        kas_ibu +
        beras
    )

    # AUTO STATUS
    if tanggal_bayar:
        status = "Lunas"
    else:
        status = "Belum Bayar"

    cursor = db.cursor(
        dictionary=True
    )

    # =====================
    # CEK DATA
    # =====================

    cek_query = """

    SELECT *

    FROM iuran

    WHERE id_rumah = %s
    AND bulan = %s
    AND tahun = %s

    """

    cursor.execute(

        cek_query,

        (
            id_rumah,
            bulan,
            tahun
        )
    )

    existing = cursor.fetchone()

    # =====================
    # UPDATE
    # =====================

    if existing:

        query = """

        UPDATE iuran

        SET
            iuran =%s,
            kas = %s,
            kas_ibu = %s,
            beras = %s,

            total = %s,

            status = %s,

            tanggal_bayar = %s

        WHERE id_iuran = %s

        """

        cursor.execute(

            query,

            (
                iuran,
                kas,
                kas_ibu,
                beras,

                total,

                status,

                tanggal_bayar,

                existing['id_iuran']
            )
        )

    # =====================
    # INSERT
    # =====================

    else:

        query = """

        INSERT INTO iuran (

            id_rumah,
            bulan,
            tahun,

            iuran,
            kas,
            kas_ibu,
            beras,

            total,
            status,

            tanggal_bayar

        )

        VALUES (

            %s, %s, %s,
            %s, %s, %s, %s,
            %s, %s,
            %s

        )
        """

        cursor.execute(

            query,

            (
                id_rumah,
                bulan,
                tahun,

                iuran,
                kas,
                kas_ibu,
                beras,

                total,
                status,

                tanggal_bayar
            )
        )

    db.commit()

    return jsonify({

        "status":
            status,

        "total":
            total,

        "message":
            "Iuran berhasil disimpan"
    })

# =========================
# GRAFIK REKAP
# =========================

@app.route('/grafik_rekap', methods=['GET'])
def grafik_rekap():

    db.ping(reconnect=True, attempts=3, delay=1)

    # Tambahkan buffered=True agar tidak ada masalah dengan cursor dalam loop
    cursor = db.cursor(
        dictionary=True,
        buffered=True
    )

    data = []

    bulan_indonesia = {

        1: "Januari",
        2: "Februari",
        3: "Maret",
        4: "April",
        5: "Mei",
        6: "Juni",
        7: "Juli",
        8: "Agustus",
        9: "September",
        10: "Oktober",
        11: "November",
        12: "Desember"

    }

    tahun = int(
        request.args.get(
            "tahun",
            datetime.now().year
        )
    )

    for bulan_angka in range(1, 13):

        bulan_db = bulan_indonesia[
            bulan_angka
        ]

        # =====================
        # IURAN
        # =====================

        cursor.execute("""

            SELECT

                IFNULL(
                    SUM(total),
                    0
                ) AS total

            FROM iuran

            WHERE

                status = 'Lunas'

                AND

                bulan = %s

                AND

                tahun = %s

        """, (

            bulan_db,
            tahun

        ))

        total_iuran = cursor.fetchone()
        # Mengambil nilai aman
        val_iuran = total_iuran['total'] if total_iuran else 0

        # =====================
        # PEMASUKAN LAIN
        # =====================

        cursor.execute("""

            SELECT

                IFNULL(
                    SUM(nominal),
                    0
                ) AS total

            FROM pemasukan

            WHERE

                MONTH(tanggal) = %s

                AND

                YEAR(tanggal) = %s

        """, (

            bulan_angka,
            tahun

        ))

        total_pemasukan = cursor.fetchone()
        # Mengambil nilai aman
        val_pemasukan_lain = total_pemasukan['total'] if total_pemasukan else 0

        # =====================
        # PENGELUARAN
        # =====================

        cursor.execute("""

            SELECT

                IFNULL(
                    SUM(nominal),
                    0
                ) AS total

            FROM pengeluaran

            WHERE

                MONTH(tanggal) = %s

                AND

                YEAR(tanggal) = %s

        """, (

            bulan_angka,
            tahun

        ))

        total_pengeluaran = cursor.fetchone()
        # Mengambil nilai aman
        val_pengeluaran = total_pengeluaran['total'] if total_pengeluaran else 0

        data.append({

            "bulan":
                bulan_db[:3],

            "pemasukan":
                int(val_iuran + val_pemasukan_lain),

            "pengeluaran":
                int(val_pengeluaran)

        })

    cursor.close()

    return jsonify(data)



# =========================
# REKAP KEUANGAN
# =========================

@app.route('/rekap', methods=['GET'])
def rekap():

    bulan = request.args.get('bulan')
    tahun = request.args.get('tahun')

    bulan_indonesia = [

        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"

    ]

    bulan_angka = (
        bulan_indonesia.index(bulan)
        + 1
    )

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor(
        dictionary=True,
        buffered=True
    )

    # =====================
    # TOTAL IURAN
    # =====================

    cursor.execute("""

        SELECT

            IFNULL(
                SUM(total),
                0
            ) AS total_iuran

        FROM iuran

        WHERE

            status = 'Lunas'

            AND

            bulan = %s

            AND

            tahun = %s

    """, (

        bulan,
        tahun

    ))

    iuran = cursor.fetchone()
    total_iuran = iuran["total_iuran"] if iuran and iuran["total_iuran"] else 0

    # =====================
    # PEMASUKAN LAIN
    # =====================

    cursor.execute("""

        SELECT

            IFNULL(
                SUM(nominal),
                0
            ) AS pemasukan_lain

        FROM pemasukan

        WHERE

            MONTH(tanggal) = %s

            AND

            YEAR(tanggal) = %s

    """, (

        bulan_angka,
        tahun

    ))

    pemasukan_lain = cursor.fetchone()
    total_pemasukan_lain = pemasukan_lain["pemasukan_lain"] if pemasukan_lain and pemasukan_lain["pemasukan_lain"] else 0

    total_pemasukan = (
        total_iuran + total_pemasukan_lain
    )

    # =====================
    # TOTAL PENGELUARAN
    # =====================

    cursor.execute("""

        SELECT

            IFNULL(
                SUM(nominal),
                0
            ) AS pengeluaran

        FROM pengeluaran

        WHERE

            MONTH(tanggal) = %s

            AND

            YEAR(tanggal) = %s

    """, (

        bulan_angka,
        tahun

    ))

    pengeluaran = cursor.fetchone()
    total_pengeluaran = pengeluaran["pengeluaran"] if pengeluaran and pengeluaran["pengeluaran"] else 0

    # Tutup cursor untuk menghindari error koneksi
    cursor.close()

    data = {

        "pemasukan":
            int(total_pemasukan),

        "pengeluaran":
            int(total_pengeluaran),

        "saldo":
            int(total_pemasukan - total_pengeluaran)

    }

    return jsonify(data)

# =========================
# DETAIL PEMASUKAN
# =========================

@app.route('/detail_pemasukan', methods=['GET'])
def detail_pemasukan():

    bulan = request.args.get('bulan')
    tahun = request.args.get('tahun')

    bulan_indonesia = [

        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"

    ]

    try:
        bulan_angka = (
            bulan_indonesia.index(bulan)
            + 1
        )
    except:
        return jsonify([])

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor(
        dictionary=True
    )

    query_iuran = """

    SELECT

        0 AS id,
        MAX(tanggal_bayar) AS tanggal,
        'Iuran Wajib' AS jenis,
        IFNULL(SUM(total),0) AS nominal,
        IFNULL(SUM(iuran),0) AS total_iuran,
        IFNULL(SUM(kas),0) AS total_kas,
        IFNULL(SUM(kas_ibu),0) AS total_kas_ibu,
        IFNULL(SUM(beras),0) AS total_beras,
        'Total iuran terkumpul' AS keterangan

    FROM iuran

    WHERE

        status = 'Lunas'

        AND

        bulan = %s

        AND

        tahun = %s

    HAVING nominal > 0

    """

    cursor.execute(
        query_iuran,
        (bulan, tahun)
    )

    hasil = cursor.fetchone()

    data_iuran = []

    if hasil:
        data_iuran.append({
            "id": 0,
            "tanggal": hasil["tanggal"],
            "jenis": "Iuran Wajib",
            "nominal": hasil["total_iuran"],
            "keterangan": "Total iuran wajib"
        })

        data_iuran.append({
            "id": 0,
            "tanggal": hasil["tanggal"],
            "jenis": "Kas",
            "nominal": hasil["total_kas"],
            "keterangan": "Total kas"
        })

        data_iuran.append({
            "id": 0,
            "tanggal": hasil["tanggal"],
            "jenis": "Kas Ibu",
            "nominal": hasil["total_kas_ibu"],
            "keterangan": "Total kas ibu"
        })

        data_iuran.append({
            "id": 0,
            "tanggal": hasil["tanggal"],
            "jenis": "Beras",
            "nominal": hasil["total_beras"],
            "keterangan": "Total beras"
        })

    query_pemasukan = """

    SELECT

        id_pemasukan AS id,
        tanggal,
        jenis,
        nominal,
        keterangan

    FROM pemasukan

    WHERE

        MONTH(tanggal) = %s

        AND

        YEAR(tanggal) = %s

    """

    cursor.execute(
        query_pemasukan,
        (bulan_angka, tahun)
    )

    data_pemasukan = cursor.fetchall()

    cursor.close()

    semua_data = (
        data_iuran + data_pemasukan
    )

    for item in semua_data:
        if item['tanggal']:
            item['tanggal'] = item['tanggal'].strftime("%Y-%m-%d")

    return jsonify(semua_data)


# =========================
# TAMBAH PEMASUKAN
# =========================

@app.route('/add_pemasukan', methods=['POST'])
def add_pemasukan():

    data = request.json

    tanggal = data['tanggal']
    jenis = data['jenis']
    nominal = int(data['nominal'])
    keterangan = data.get('keterangan', '')

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor()

    query = """

    INSERT INTO pemasukan (

        tanggal,
        jenis,
        nominal,
        keterangan

    )

    VALUES (

        %s, %s, %s, %s

    )

    """

    cursor.execute(
        query,
        (tanggal, jenis, nominal, keterangan)
    )

    db.commit()
    cursor.close()

    return jsonify({

        "status": "success"

    })

# =========================
# EDIT & HAPUS PEMASUKAN
# =========================

@app.route('/edit_pemasukan/<int:id>', methods=['POST'])
def edit_pemasukan(id):

    data = request.json

    tanggal = data['tanggal']
    jenis = data['jenis']
    nominal = int(data['nominal'])
    keterangan = data.get('keterangan', '')

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor()

    query = """

    UPDATE pemasukan

    SET

        tanggal=%s,
        jenis=%s,
        nominal=%s,
        keterangan=%s

    WHERE id_pemasukan=%s

    """

    cursor.execute(
        query,
        (tanggal, jenis, nominal, keterangan, id)
    )

    db.commit()
    cursor.close()

    return jsonify({"status": "success"})


@app.route('/hapus_pemasukan/<int:id>', methods=['DELETE'])
def hapus_pemasukan(id):

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor()

    query = """

    DELETE FROM pemasukan
    WHERE id_pemasukan=%s

    """

    cursor.execute(query, (id,))

    db.commit()
    cursor.close()

    return jsonify({"status": "success"})

# =========================
# DETAIL PENGELUARAN
# =========================

@app.route('/detail_pengeluaran', methods=['GET'])
def detail_pengeluaran():

    bulan = request.args.get('bulan')
    tahun = request.args.get('tahun')

    bulan_indonesia = [

        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"

    ]

    try:
        bulan_angka = (
            bulan_indonesia.index(bulan)
            + 1
        )
    except:
        return jsonify([])

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor(
        dictionary=True
    )

    query = """

    SELECT
        id_pengeluaran AS id,
        jenis,
        nominal,
        keterangan,
        tanggal

    FROM pengeluaran

    WHERE

        MONTH(tanggal) = %s

        AND

        YEAR(tanggal) = %s

    ORDER BY tanggal DESC

    """

    cursor.execute(
        query,
        (bulan_angka, tahun)
    )

    data = cursor.fetchall()

    cursor.close()

    for item in data:
        if item['tanggal']:
            item['tanggal'] = item['tanggal'].strftime("%Y-%m-%d")

    return jsonify(data)


# =========================
# TAMBAH PENGELUARAN
# =========================

@app.route('/add_pengeluaran', methods=['POST'])
def add_pengeluaran():

    data = request.json

    jenis = data['jenis']
    nominal = int(data['nominal'])
    keterangan = data['keterangan']
    tanggal = data['tanggal']

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor()

    query = """

    INSERT INTO pengeluaran (

        jenis,
        nominal,
        keterangan,
        tanggal
    )

    VALUES (

        %s, %s, %s, %s

    )

    """

    cursor.execute(
        query,
        (jenis, nominal, keterangan, tanggal)
    )

    db.commit()
    cursor.close()

    return jsonify({

        "status": "success"

    })

# =========================
# EDIT & HAPUS PENGELUARAN
# =========================

@app.route('/edit_pengeluaran/<int:id>', methods=['POST'])
def edit_pengeluaran(id):

    data = request.json

    jenis = data['jenis']
    nominal = int(data['nominal'])
    keterangan = data['keterangan']
    tanggal = data['tanggal']

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor()

    query = """

    UPDATE pengeluaran

    SET

        jenis=%s,
        nominal=%s,
        keterangan=%s,      
        tanggal=%s

    WHERE id_pengeluaran=%s

    """

    cursor.execute(
        query,
        (jenis, nominal, keterangan, tanggal, id)
    )

    db.commit()
    cursor.close()

    return jsonify({"status": "success"})


@app.route('/hapus_pengeluaran/<int:id>', methods=['DELETE'])
def hapus_pengeluaran(id):

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor()

    query = """

    DELETE FROM pengeluaran
    WHERE id_pengeluaran=%s

    """

    cursor.execute(query, (id,))

    db.commit()
    cursor.close()

    return jsonify({"status": "success"})

# =========================
# AGENDA
# =========================

@app.route('/agenda', methods=['GET'])
def get_agenda():
    tahun = request.args.get('tahun')
    cursor = db.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM agenda WHERE YEAR(tgl_mulai) = %s", (tahun,))
    
    data = cursor.fetchall()
    cursor.close()
    return jsonify(data)

# =========================
# TAMBAH AGENDA
# =========================

@app.route('/add_agenda', methods=['POST'])
def add_agenda():
    data = request.json
    
    # Ambil data dari body JSON Flutter
    nama = data['nama']
    tgl_mulai = data['tgl_mulai']
    tgl_berakhir = data['tgl_berakhir']

    db.ping(reconnect=True, attempts=3, delay=1)
    cursor = db.cursor()

    # Sesuaikan query dengan kolom tabel Anda
    query = """
    INSERT INTO agenda (nama, tgl_mulai, tgl_berakhir) 
    VALUES (%s, %s, %s)
    """

    cursor.execute(query, (nama, tgl_mulai, tgl_berakhir))
    
    db.commit()
    cursor.close()

    return jsonify({"status": "success"})

# =========================
# DETAIL AGENDA
# =========================

@app.route('/agenda_summary', methods=['GET'])
def get_agenda_summary():
    id_agenda = request.args.get('id_agenda')
    cursor = db.cursor(dictionary=True)
    
    # Menghitung total per jenis
    cursor.execute("""
        SELECT jenis, SUM(nominal) as total 
        FROM transaksi 
        WHERE id_agenda = %s 
        GROUP BY jenis
    """, (id_agenda,))
    
    data = cursor.fetchall()
    
    # Inisialisasi summary
    summary = {"masuk": 0, "keluar": 0}
    for row in data:
        summary[row['jenis']] = row['total']
        
    return jsonify({
        "pemasukan": summary['masuk'],
        "pengeluaran": summary['keluar'],
        "saldo": summary['masuk'] - summary['keluar']
    })


# =========================
# EDIT AGENDA
# =========================
@app.route('/edit_agenda', methods=['POST'])
def edit_agenda():
    data = request.json

    id_agenda = data['id_agenda']
    nama = data['nama']
    tgl_mulai = data['tgl_mulai']
    tgl_berakhir = data['tgl_berakhir']

    db.ping(reconnect=True, attempts=3, delay=1)
    cursor = db.cursor()

    query = """
    UPDATE agenda
    SET nama = %s,
        tgl_mulai = %s,
        tgl_berakhir = %s
    WHERE id_agenda = %s
    """

    cursor.execute(
        query,
        (
            nama,
            tgl_mulai,
            tgl_berakhir,
            id_agenda
        )
    )

    db.commit()
    cursor.close()

    return jsonify({
        "status": "success"
    })
# =========================
# HAPUS AGENDA
# =========================
@app.route('/hapus_agenda', methods=['POST'])
def hapus_agenda():

    id_agenda = request.form['id_agenda']

    cursor = db.cursor()

    cursor.execute(
        "DELETE FROM transaksi WHERE id_agenda=%s",
        (id_agenda,)
    )

    cursor.execute(
        "DELETE FROM agenda WHERE id_agenda=%s",
        (id_agenda,)
    )

    db.commit()
    cursor.close()

    return jsonify({
        "success": True,
        "message": "Agenda berhasil dihapus"
    })

# =========================
# TRANSAKSI
# =========================

@app.route('/transaksi', methods=['GET'])
def get_transaksi():

    id_agenda = request.args.get('id_agenda')

    cursor = db.cursor(dictionary=True)

    query = """
        SELECT
            transaksi.*,
            warga.nama AS nama_warga,
            rumah.no_rumah
        FROM transaksi
        LEFT JOIN warga
            ON transaksi.id_warga = warga.id_warga
        LEFT JOIN rumah
            ON warga.id_warga = rumah.id_warga
        WHERE transaksi.id_agenda = %s
    """

    cursor.execute((query), (id_agenda,))
    data = cursor.fetchall()

    # UBAH FORMAT TANGGAL AGAR TIDAK GMT
    for item in data:
        if item['tgl']:
            item['tgl'] = item['tgl'].strftime('%Y-%m-%d')

    cursor.close()

    return jsonify(data)

# =========================
# TAMBAH TRANSAKSI
# =========================

@app.route('/add_transaksi', methods=['POST'])
def add_transaksi():

    data = request.form

    id_warga = data.get('id_warga')
    id_warga = int(id_warga) if id_warga else None

    tgl = data.get('tgl')

    try:
        cursor = db.cursor()

        query = """
            INSERT INTO transaksi
            (
                id_agenda,
                id_warga,
                jenis,
                kategori,
                nominal,
                ket,
                tgl
            )
            VALUES
            (
                %s,%s,%s,%s,%s,%s,%s
            )
        """

        cursor.execute(
            query,
            (
                data['id_agenda'],
                id_warga,
                data['jenis'],
                data['kategori'],
                int(data['nominal']),
                data['ket'],
                tgl
            )
        )

        db.commit()
        cursor.close()

        return jsonify({
            "status": "success",
            "message": "Transaksi berhasil ditambahkan"
        })

    except Exception as e:
        print(e)

        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

# =========================
# EDIT TRANSAKSI
# =========================
@app.route('/edit_transaksi', methods=['POST'])
def edit_transaksi():

    data = request.form
    print("DATA MASUK :", data)

    id_trx = data['id']
    kategori = data['kategori']
    nominal = data['nominal'].replace('.', '').replace(',', '')
    ket = data['ket']
    tgl = data['tgl']

    try:
        # kalau dari flutter masih format GMT
        if 'GMT' in tgl:
            from email.utils import parsedate_to_datetime

            dt = parsedate_to_datetime(tgl)
            tgl = dt.strftime('%Y-%m-%d')

        print(
            "ID :", id_trx,
            "Kategori :", kategori,
            "Nominal :", nominal,
            "Ket :", ket,
            "Tanggal :", tgl
        )

        cursor = db.cursor()

        query = """
            UPDATE transaksi
            SET
                kategori=%s,
                nominal=%s,
                ket=%s,
                tgl=%s
            WHERE id=%s
        """

        cursor.execute(
            query,
            (
                kategori,
                nominal,
                ket,
                tgl,
                id_trx
            )
        )

        print("ROW BERUBAH :", cursor.rowcount)

        db.commit()
        cursor.close()

        return jsonify({
            "status": "success",
            "message": "Data berhasil diupdate"
        })

    except Exception as e:
        print("ERROR :", e)

        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500
    
# =========================
# HAPUS TRANSAKSI
# =========================
@app.route('/hapus_transaksi/<id>', methods=['DELETE'])
def hapus_transaksi(id):
    try:
        cursor = db.cursor()
        cursor.execute("DELETE FROM transaksi WHERE id=%s", (id,))
        db.commit()
        cursor.close()
        return jsonify({"status": "success", "message": "Data berhasil dihapus"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# =========================
# HALAMAN PENGUMUMAN
# =========================
@app.route('/pengumuman', methods=['GET'])
def get_pengumuman():
    cursor = db.cursor(dictionary=True)
    # Mengambil semua pengumuman, diurutkan dari yang terbaru (ID terbesar)
    cursor.execute("SELECT * FROM pengumuman ORDER BY id DESC")
    data = cursor.fetchall()
    cursor.close()
    return jsonify(data)

@app.route('/add_pengumuman', methods=['POST'])
def add_pengumuman():
    judul = request.form.get('judul')
    isi = request.form.get('isi')
    tgl = request.form.get('tgl') # Flutter mengirim format 'yyyy-MM-dd HH:mm:ss'

    cursor = db.cursor()
    # Langsung masukkan karena format sudah standar MySQL
    query = "INSERT INTO pengumuman (judul, isi, tgl) VALUES (%s, %s, %s)"
    cursor.execute(query, (judul, isi, tgl))
    db.commit()
    cursor.close()
    
    return jsonify({"status": "success", "message": "Pengumuman berhasil dibuat"})

@app.route('/pengumuman/<int:id>', methods=['GET'])
def detail_pengumuman(id):

    cursor = db.cursor(dictionary=True)

    cursor.execute("""

        SELECT *

        FROM pengumuman

        WHERE id = %s

    """, (id,))

    data = cursor.fetchone()

    if data:

        return jsonify(data)

    return jsonify({
        "status": "error",
        "message": "Pengumuman tidak ditemukan"
    }), 404


# EDIT PENGUMUMAN
@app.route('/edit_pengumuman/<int:id>', methods=['PUT'])
def edit_pengumuman(id):
    try:
        data = request.json
        judul = data.get("judul")
        isi = data.get("isi")

        cursor = db.cursor()
        cursor.execute("""
            UPDATE pengumuman
            SET
                judul = %s,
                isi = %s,
                tgl = NOW()
            WHERE id = %s

        """, (
            judul,
            isi,
            id
        ))

        db.commit()

        return jsonify({
            "status": "success",
            "message": "Pengumuman berhasil diperbarui"
        })

    except Exception as e:

        db.rollback()

        return jsonify({

            "status": "error",
            "message": str(e)

        }), 500
    
# =========================
# HAPUS PENGUMUMAN
# =========================

@app.route('/hapus_pengumuman/<int:id>', methods=['DELETE'])
def hapus_pengumuman(id):
    try:
        cursor = db.cursor()
        query = """
            DELETE FROM pengumuman
            WHERE id = %s
        """

        cursor.execute(query, (id,))

        db.commit()

        return jsonify({
            "status": "success",
            "message": "Pengumuman berhasil dihapus"
        })

    except Exception as e:
        db.rollback()
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500



# ---------------------------------------------------------------------------------------------
# WARGA
# ---------------------------------------------------------------------------------------------

# =========================
# IURAN SAYA
# =========================
@app.route('/iuran_saya/<int:id_warga>', methods=['GET'])
def iuran_saya(id_warga):

    cursor = db.cursor(dictionary=True)

    tahun = request.args.get("tahun", type=int)

    if tahun is None:
        tahun = datetime.now().year

    bulan_list = [

        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"

    ]

    query = """

        SELECT

            rumah.id_rumah,

            iuran.id_iuran,
            iuran.bulan,
            iuran.tahun,
            iuran.status

        FROM rumah

        LEFT JOIN iuran

            ON rumah.id_rumah = iuran.id_rumah

            AND iuran.tahun = %s

        WHERE rumah.id_warga = %s

    """

    cursor.execute(query, (tahun, id_warga))

    data_db = cursor.fetchall()

    hasil = []

    for bulan in bulan_list:

        ditemukan = None

        for item in data_db:

            if item["bulan"] == bulan:

                ditemukan = item
                break

        if ditemukan:

            hasil.append({

                "id_rumah": ditemukan["id_rumah"],
                "id_iuran": ditemukan["id_iuran"],
                "bulan": bulan,
                "tahun": ditemukan["tahun"],
                "status": ditemukan["status"]

            })

        else:

            hasil.append({

                "id_rumah": data_db[0]["id_rumah"] if data_db else None,
                "id_iuran": None,
                "bulan": bulan,
                "tahun": tahun,
                "status": "Belum Bayar"

            })

    cursor.close()

    return jsonify(hasil)

# =========================
# BANNER PENGUMUMAN
# =========================
@app.route('/pengumuman-terbaru')
def pengumuman_terbaru():

    db.ping(reconnect=True, attempts=3, delay=1)

    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT *
        FROM pengumuman
        ORDER BY id DESC
        LIMIT 1
    """)

    data = cursor.fetchone()

    cursor.close()

    if data:
        return jsonify(data)

    return jsonify({})

# =========================
# EDIT PROFIL WARGA
# =========================
@app.route('/edit_profil_warga/<int:id>', methods=['PUT'])
def edit_profil_warga(id):
    try:
        data = request.json

        nama = data.get("nama")
        no_hp = data.get("no_hp")

        cursor = db.cursor()

        cursor.execute("""
            UPDATE warga
            SET
                nama=%s,
                no_hp=%s
            WHERE id_warga=%s
        """, (
            nama,
            no_hp,
            id,
        ))

        db.commit()

        return jsonify({
            "status": "success",
            "message": "Profil berhasil diperbarui"
        })

    except Exception as e:
        db.rollback()
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500
    
# =========================
# KONTAK PENGURUS
# =========================
@app.route('/pengurus', methods=['GET'])
def get_pengurus():
    try:
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                id_pengurus,
                nama,
                jabatan,
                no_hp
            FROM pengurus
            LIMIT 1
        """)

        data = cursor.fetchone()

        if data:
            return jsonify(data)

        return jsonify({
            "message": "Data pengurus tidak ditemukan"
        }), 404

    except Exception as e:
        return jsonify({
            "message": str(e)
        }), 500
    
# =========================
# RUN APP
# =========================
import os

if __name__ == '__main__':

    if os.environ.get("WERKZEUG_RUN_MAIN") == "true":
        print("Scheduler Started...")
        scheduler.start()

    app.run(
        host='0.0.0.0',
        port=int(os.environ.get("PORT", 5000)),
        debug=False,
        threaded=False
    )