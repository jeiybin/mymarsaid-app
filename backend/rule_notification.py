from datetime import datetime

# ======================
# Mapping Bulan Indonesia
# ======================
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

# ======================
# Menentukan Kategori
# ======================
def get_kategori(jumlah_telat):
    """
    Menentukan kategori warga berdasarkan
    jumlah keterlambatan 6 bulan terakhir.

    A = Tepat Waktu
    B = Kadang Terlambat
    C = Sering Terlambat
    """

    if jumlah_telat <= 1:
        return "A"

    elif jumlah_telat <= 3:
        return "B"

    else:
        return "C"

# ======================
# Menghitung jumlah telat
# ======================
def hitung_telat(cursor, id_rumah):
    """
    Menghitung jumlah keterlambatan pembayaran
    dalam 6 bulan terakhir.
    """

    cursor.execute("""
        SELECT tanggal_bayar
        FROM iuran
        WHERE id_rumah = %s
        ORDER BY tahun DESC, id_iuran DESC
        LIMIT 6
    """, (id_rumah,))

    data = cursor.fetchall()

    jumlah_telat = 0

    for row in data:

        tanggal = row["tanggal_bayar"]

        if tanggal is None:
            continue

        if tanggal.day > 24:
            jumlah_telat += 1

    return jumlah_telat

# ======================
# Cek jadwal notifikasi
# ======================
def cek_jadwal(kategori):

    hari = datetime.now().day

    jatuh_tempo = 24

    # ======================
    # Kategori A
    # ======================

    if kategori == "A":

        return hari == jatuh_tempo - 1

    # ======================
    # Kategori B
    # ======================

    elif kategori == "B":

        return hari in [
            jatuh_tempo - 3,
            jatuh_tempo - 2,
            jatuh_tempo - 1
        ]

    # ======================
    # Kategori C
    # ======================

    elif kategori == "C":

        return hari in [
            jatuh_tempo - 7,
            jatuh_tempo - 3,
            jatuh_tempo - 2,
            jatuh_tempo - 1
        ]

    return False

# ======================
# Cek jatuh tempo
# ======================
def cek_setelah_jatuh_tempo():

    # MODE TEST
    hari = datetime.now().day

    jatuh_tempo = 24

    if hari <= jatuh_tempo:
        return False

    selisih = hari - jatuh_tempo

    return selisih % 3 == 0


# ======================
# Cek Status Pembayaran
# ======================
def sudah_lunas(cursor, id_rumah):

    bulan = bulan_indonesia[datetime.now().month]
    tahun = datetime.now().year

    cursor.execute("""
        SELECT status
        FROM iuran
        WHERE id_rumah = %s
        AND bulan = %s
        AND tahun = %s
        LIMIT 1
    """, (
        id_rumah,
        bulan,
        tahun
    ))

    data = cursor.fetchone()

    # Jika belum ada data iuran bulan ini
    if not data:
        return False

    return data["status"] == "Lunas"

# ======================
# cek awal bulan
# ======================
def cek_awal_bulan():

    return True