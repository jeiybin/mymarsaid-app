from firebase_admin import messaging

def send_notification(db, id_user, title, body):
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT fcm_token
        FROM users
        WHERE id=%s
    """, (id_user,))

    user = cursor.fetchone()
    if not user:
        return False
    if not user["fcm_token"]:
        return False
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=user["fcm_token"],
    )
    try:
        messaging.send(message)
        return True
    except Exception as e:
        print(e)
        return False