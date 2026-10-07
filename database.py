import requests

API_URL = "http://38.224.68.171:5000/api"

def ejecutar_login(user):
    try:
        response = requests.post(f"{API_URL}/login", json={"user": user}, timeout=10)
        return response.json() if response.status_code == 200 else None
    except Exception as ex:
        print(f"Error de conexión en login: {ex}")
        return None

def obtener_info_alumno(id_alumno):
    try:
        response = requests.get(f"{API_URL}/alumno", params={"id": id_alumno}, timeout=10)
        return response.json() if response.status_code == 200 else None
    except Exception as ex:
        print(f"Error al obtener información del alumno: {ex}")
        return None

def obtener_cuotas_pendientes(id_alumno):
    try:
        response = requests.get(f"{API_URL}/cuotas_pendientes", params={"id": id_alumno}, timeout=10)
        return response.json() if response.status_code == 200 else []
    except Exception as ex:
        print(f"Error al obtener cuotas pendientes: {ex}")
        return []

def obtener_cuotas_pagadas(id_alumno):
    try:
        response = requests.get(f"{API_URL}/cuotas_pagadas", params={"id": id_alumno}, timeout=10)
        return response.json() if response.status_code == 200 else []
    except Exception as ex:
        print(f"Error al obtener cuotas pagadas: {ex}")
        return []

def obtener_comunicados_no_leidos(id_alumno):
    try:
        response = requests.get(f"{API_URL}/comunicados_no_leidos", params={"id": id_alumno}, timeout=10)
        return response.json() if response.status_code == 200 else []
    except Exception as ex:
        print(f"Error al obtener comunicados no leídos: {ex}")
        return []

def obtener_comunicados_leidos(id_alumno):
    try:
        response = requests.get(f"{API_URL}/comunicados_leidos", params={"id": id_alumno}, timeout=10)
        return response.json() if response.status_code == 200 else []
    except Exception as ex:
        print(f"Error al obtener comunicados leídos: {ex}")
        return []

def actualizar_estado_comunicado(id_comunica):
    try:
        response = requests.post(f"{API_URL}/actualizar_comunicado", json={"id": id_comunica}, timeout=10)
        return response.status_code == 200
    except Exception as ex:
        print(f"Error al actualizar estado del comunicado: {ex}")
        return False

def registrar_token_fcm(id_alumno, token_fcm):
    try:
        response = requests.post(
            f"{API_URL}/registrar_token_fcm", 
            json={"id_alumno": id_alumno, "token_fcm": token_fcm}, 
            timeout=10
        )
        if response.status_code == 200:
            print(f"OK: Token registrado vía API para Id_Alumno: {id_alumno}")
            return True
        else:
            print(f"Error API ({response.status_code}): No se pudo guardar el token FCM")
            return False
    except Exception as ex:
        print(f"Error al registrar token FCM vía API: {ex}")
        return False
