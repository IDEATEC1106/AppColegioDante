from datetime import datetime
from kivy.lang import Builder
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.uix.widget import Widget
from kivymd.app import MDApp
from kivymd.uix.dialog import MDDialog, MDDialogHeadlineText, MDDialogButtonContainer
from kivymd.uix.button import MDButton, MDButtonText
from kivymd.uix.tab import MDTabsPrimary, MDTabsItem

# Importamos nuestro módulo local de base de datos externo
import database

class LoginScreen(Screen):
    def verificar_login(self):
        user = self.ids.user_input.text.strip()
        password = self.ids.password_input.text.strip()
        
        if not user or not password:
            self.mostrar_dialogo("Campos Incompletos", "Por favor, llene los dos campos.")
            return

        # Llamada limpia a la función del archivo database.py
        row_login = database.ejecutar_login(user)

        if row_login:
            ndoc_apo_db = str(row_login.get("NDocApo") or row_login.get("ndocapo") or "").strip()
            nombre_apoderado = row_login.get("Apoderado") or row_login.get("apoderado") or "Apoderado Registrado"
            nombre_estudiante_login = row_login.get("estudiante") or row_login.get("Estudiante") or "Estudiante"
            id_alumno = row_login.get("Id_alumno") or row_login.get("id_alumno") or row_login.get("Id_Alumno")
            
            if password == ndoc_apo_db:
                app = MDApp.get_running_app()
                
                app.datos_alumno = {
                    "codigo": user,
                    "nombre_completo": nombre_estudiante_login,
                    "nro_doc": password,
                    "id_alumno": id_alumno,
                    "apoderado": nombre_apoderado,
                    "grado": "-",
                    "seccion": "-",
                    "turno": "-"
                }
                
                home_screen = self.manager.get_screen('home')
                home_screen.ids.header_bienvenida.text = f"Apoderado: {app.datos_alumno['apoderado']}"
                home_screen.ids.header_detalles.text = f"Estudiante: {app.datos_alumno['nombre_completo']}"
                
                self.manager.current = 'home'
                self.ids.user_input.text = ""
                self.ids.password_input.text = ""
            else:
                self.mostrar_dialogo("Error de Acceso", "La contraseña (Documento del Apoderado) es incorrecta.")
        else:
            self.mostrar_dialogo("Error de Acceso", "El código de alumno ingresado no existe.")

    def mostrar_dialogo(self, titulo, mensaje):
        dialogo = MDDialog(
            MDDialogHeadlineText(text=titulo),
            MDDialogButtonContainer(
                Widget(),
                MDButton(
                    MDButtonText(text="OK"),
                    style="text",
                    on_release=lambda x: dialogo.dismiss()
                ),
            )
        )
        dialogo.open()


class HomeScreen(Screen):
    def ir_a_informacion_estudiante(self):
        app = MDApp.get_running_app()
        if not app.datos_alumno:
            print("Error: No hay datos de sesión del alumno.")
            return
            
        id_alumno = app.datos_alumno.get("id_alumno")
        
        try:
            row_alumno = database.obtener_info_alumno(id_alumno) if id_alumno is not None else None
            print(f"DEBUG BD - ID: {id_alumno} | Respuesta: {str(row_alumno)}")
            
            if row_alumno:
                app.datos_alumno["grado"] = row_alumno.get("grado") or row_alumno.get("Grado") or "-"
                app.datos_alumno["seccion"] = row_alumno.get("seccion") or row_alumno.get("Seccion") or "-"
                app.datos_alumno["turno"] = row_alumno.get("turno") or row_alumno.get("Turno") or "-"
                if row_alumno.get("apellidos_nombres") or row_alumno.get("Apellidos_Nombres"):
                    app.datos_alumno["nombre_completo"] = row_alumno.get("apellidos_nombres") or row_alumno.get("Apellidos_Nombres")
                    
            student_screen = self.manager.get_screen('student_info')
            student_screen.ids.info_codigo.text = str(app.datos_alumno["codigo"])
            student_screen.ids.info_estudiante.text = str(app.datos_alumno["nombre_completo"])
            student_screen.ids.info_nrodoc.text = str(app.datos_alumno["nro_doc"])
            student_screen.ids.info_grado.text = str(app.datos_alumno["grado"])
            student_screen.ids.info_seccion.text = str(app.datos_alumno["seccion"])
            student_screen.ids.info_turno.text = str(app.datos_alumno["turno"])
            student_screen.ids.info_anio.text = str(datetime.now().year)
            self.manager.current = 'student_info'
            
        except Exception as e:
            print(f"Error de Conexión en información de alumno: {str(e)}")

    def ir_a_control_pagos(self):
        """BOTÓN 2: CONTROL DE PAGOS REALES CON DISEÑO AVANZADO"""
        app = MDApp.get_running_app()
        if not app.datos_alumno:
            return

        id_alumno = app.datos_alumno.get("id_alumno")
        payments_screen = self.manager.get_screen('payments')
        
        container_pen = payments_screen.ids.container_pendientes
        container_pag = payments_screen.ids.container_realizados
        
        container_pen.clear_widgets()
        container_pag.clear_widgets()

        rows_pendientes = database.obtener_cuotas_pendientes(id_alumno) if id_alumno is not None else []
        rows_realizados = database.obtener_cuotas_pagadas(id_alumno) if id_alumno is not None else []

        from kivymd.uix.card import MDCard
        from kivymd.uix.label import MDLabel
        from kivymd.uix.boxlayout import MDBoxLayout
        from kivymd.uix.label import MDIcon
        from kivy.metrics import dp

        # --- GRID PENDIENTES (ROJO) ---
        if not rows_pendientes:
            lbl = MDLabel(text="No cuenta con deudas pendientes.", halign="center", theme_text_color="Secondary")
            container_pen.add_widget(lbl)
        else:
            for item in rows_pendientes:
                comprobante = item.get("Comprobante") or item.get("comprobante") or "-"
                fch_emi = str(item.get("Fch_Emi") or item.get("fch_emi") or "-")
                conceptos = item.get("Conceptos") or item.get("conceptos") or "Cuota Escolar"
                total = str(item.get("Total") or item.get("total") or "0.00")
                fch_pago = str(item.get("Fch_Pago") or item.get("fch_pago") or "Pendiente")

                card_pen = MDCard(
                    orientation='horizontal', padding=dp(12), spacing=dp(14),
                    size_hint_y=None, height=dp(115), md_bg_color=(1, 0.94, 0.94, 1), radius=[dp(12)]
                )
                
                icon_layout = MDBoxLayout(size_hint_x=None, width=dp(40), pos_hint={"center_y": 0.5})
                icon_layout.add_widget(MDIcon(icon="cash-register", theme_icon_color="Custom", icon_color=(0.7, 0.1, 0.1, 1)))
                
                text_layout = MDBoxLayout(orientation="vertical", spacing=dp(2))
                text_layout.add_widget(MDLabel(text=f"Doc: {comprobante}", font_style="Body", role="medium", bold=True))
                text_layout.add_widget(MDLabel(text=conceptos, font_style="Body", role="small"))
                text_layout.add_widget(MDLabel(text=f"Emisión: {fch_emi}  |  Vence: {fch_pago}", font_style="Body", role="small", theme_text_color="Secondary"))
                text_layout.add_widget(MDLabel(text=f"Total: S/. {total}", font_style="Body", role="medium", bold=True, theme_text_color="Custom", text_color=(0.7, 0.1, 0.1, 1)))
                
                card_pen.add_widget(icon_layout)
                card_pen.add_widget(text_layout)
                container_pen.add_widget(card_pen)

        # --- GRID REALIZADOS (VERDE) ---
        if not rows_realizados:
            lbl = MDLabel(text="No se registran pagos efectuados.", halign="center", theme_text_color="Secondary")
            container_pag.add_widget(lbl)
        else:
            for item in rows_realizados:
                comprobante = item.get("Comprobante") or item.get("comprobante") or "-"
                fch_pago = str(item.get("Fch_Pago") or item.get("fecpago") or item.get("fch_pago") or "-")
                conceptos = item.get("Conceptos") or item.get("conceptos") or "Cuota Pagada"
                total = str(item.get("Total") or item.get("total") or "0.00")
                modo = item.get("Modo") or item.get("modo") or "Efectivo/Banco"

                card_pag = MDCard(
                    orientation='horizontal', padding=dp(12), spacing=dp(14),
                    size_hint_y=None, height=dp(115), md_bg_color=(0.92, 0.97, 0.92, 1), radius=[dp(12)]
                )
                
                icon_layout = MDBoxLayout(size_hint_x=None, width=dp(40), pos_hint={"center_y": 0.5})
                icon_layout.add_widget(MDIcon(icon="check-circle", theme_icon_color="Custom", icon_color=(0.1, 0.5, 0.1, 1)))
                
                text_layout = MDBoxLayout(orientation="vertical", spacing=dp(2))
                text_layout.add_widget(MDLabel(text=f"Comprobante: {comprobante}", font_style="Body", role="medium", bold=True))
                text_layout.add_widget(MDLabel(text=conceptos, font_style="Body", role="small"))
                text_layout.add_widget(MDLabel(text=f"Fecha: {fch_pago}  |  Modo: {modo}", font_style="Body", role="small", theme_text_color="Secondary"))
                text_layout.add_widget(MDLabel(text=f"Total Pagado: S/. {total}", font_style="Body", role="medium", bold=True, theme_text_color="Custom", text_color=(0.1, 0.5, 0.1, 1)))
                
                card_pag.add_widget(icon_layout)
                card_pag.add_widget(text_layout)
                container_pag.add_widget(card_pag)

        self.manager.current = 'payments'


    def ir_a_comunicados(self):
        """BOTÓN 3: COMUNICADOS CON PROCEDIMIENTOS SEPARADOS Y DETALLES DE LECTURA"""
        app = MDApp.get_running_app()
        if not app.datos_alumno:
            return

        id_alumno = app.datos_alumno.get("id_alumno")
        notif_screen = self.manager.get_screen('notifications')
        
        container_no_leidos = notif_screen.ids.container_no_leidos
        container_leidos = notif_screen.ids.container_leidos
        
        container_no_leidos.clear_widgets()
        container_leidos.clear_widgets()

        comunicados_no_leidos = database.obtener_comunicados_no_leidos(id_alumno) if id_alumno is not None else []
        comunicados_leidos = database.obtener_comunicados_leidos(id_alumno) if id_alumno is not None else []

        from kivymd.uix.card import MDCard
        from kivymd.uix.label import MDLabel, MDIcon
        from kivymd.uix.boxlayout import MDBoxLayout
        from kivymd.uix.button import MDButton, MDButtonText
        from kivy.metrics import dp

        if not comunicados_no_leidos:
            container_no_leidos.add_widget(MDLabel(text="No tienes comunicados pendientes de lectura.", halign="center", theme_text_color="Secondary"))
        else:
            for item in comunicados_no_leidos:
                fecha = str(item.get("Fecha") or item.get("fecha") or "-")
                asunto = item.get("Asunto") or item.get("asunto") or "Sin Asunto"
                remitente = item.get("Remitente") or item.get("remitente") or "Dirección Académica"
                detalle = item.get("Detalle") or item.get("detalle") or "No hay contenido disponible."
                id_comunica = item.get("id_comunica") or item.get("Id_Comunica") or item.get("id_comunicado")

                card = MDCard(
                    orientation='horizontal', padding=dp(12), spacing=dp(14),
                    size_hint_y=None, height=dp(130), md_bg_color=(0.94, 0.96, 0.99, 1), radius=[dp(12)]
                )
                
                icon_layout = MDBoxLayout(size_hint_x=None, width=dp(35), pos_hint={"center_y": 0.5})
                icon_layout.add_widget(MDIcon(icon="email-outline", theme_icon_color="Custom", icon_color=(0.0, 0.45, 0.45, 1)))
                
                content_layout = MDBoxLayout(orientation="vertical", spacing=dp(1))
                content_layout.add_widget(MDLabel(text=f"Fecha: {fecha}", font_style="Body", role="small", theme_text_color="Secondary"))
                content_layout.add_widget(MDLabel(text=f"De: {remitente}", font_style="Body", role="small", bold=True))
                content_layout.add_widget(MDLabel(text=asunto, font_style="Body", role="medium"))
                
                btn_leer = MDButton(
                    style="text", size_hint_x=None, width=dp(120), pos_hint={"center_x": 0.85},
                    on_release=lambda x, a=asunto, d=detalle, id_c=id_comunica: notif_screen.mostrar_detalle_comunicado(a, d, id_c)
                )
                btn_leer.add_widget(MDButtonText(text="VER DETALLE", theme_text_color="Custom", text_color=(0.0, 0.45, 0.45, 1)))
                content_layout.add_widget(btn_leer)

                card.add_widget(icon_layout)
                card.add_widget(content_layout)
                container_no_leidos.add_widget(card)

        if not comunicados_leidos:
            container_leidos.add_widget(MDLabel(text="No hay registro de comunicados archivados.", halign="center", theme_text_color="Secondary"))
        else:
            for item in comunicados_leidos:
                fecha = str(item.get("Fecha") or item.get("fecha") or "-")
                asunto = item.get("Asunto") or item.get("asunto") or "Sin Asunto"
                remitente = item.get("Remitente") or item.get("remitente") or "Dirección Académica"
                detalle = item.get("Detalle") or item.get("detalle") or "No hay contenido disponible."
                id_comunica = item.get("id_comunica") or item.get("Id_Comunica") or item.get("id_comunicado")
                
                fch_lectura = str(item.get("leido") or item.get("Leido") or item.get("FechaLectura") or "-")
                hora_lectura = str(item.get("Hora") or item.get("hora") or item.get("HoraLectura") or "-")

                card = MDCard(
                    orientation='horizontal', padding=dp(12), spacing=dp(14),
                    size_hint_y=None, height=dp(140), md_bg_color=(0.96, 0.96, 0.96, 1), radius=[dp(12)]
                )
                
                icon_layout = MDBoxLayout(size_hint_x=None, width=dp(35), pos_hint={"center_y": 0.5})
                icon_layout.add_widget(MDIcon(icon="email-open-outline", theme_icon_color="Custom", icon_color=(0.5, 0.5, 0.5, 1)))
                
                content_layout = MDBoxLayout(orientation="vertical", spacing=dp(1))
                content_layout.add_widget(MDLabel(text=f"Emitido: {fecha}", font_style="Body", role="small", theme_text_color="Secondary"))
                content_layout.add_widget(MDLabel(text=f"De: {remitente}", font_style="Body", role="small", bold=True))
                content_layout.add_widget(MDLabel(text=asunto, font_style="Body", role="medium"))
                
                content_layout.add_widget(MDLabel(
                    text=f"Leído el: {fch_lectura}   A las: {hora_lectura}", 
                    font_style="Body", role="small", 
                    theme_text_color="Custom", text_color=(0.1, 0.5, 0.1, 1)
                ))
                
                btn_leer = MDButton(
                    style="text", size_hint_x=None, width=dp(120), pos_hint={"center_x": 0.85},
                    on_release=lambda x, a=asunto, d=detalle, id_c=id_comunica: notif_screen.mostrar_detalle_comunicado(a, d, id_c)
                )
                btn_leer.add_widget(MDButtonText(text="VER DETALLE", theme_text_color="Custom", text_color=(0.0, 0.45, 0.45, 1)))
                content_layout.add_widget(btn_leer)

                card.add_widget(icon_layout)
                card.add_widget(content_layout)
                container_leidos.add_widget(card)

        self.manager.current = 'notifications'
        
    def opcion_desarrollo(self, nombre_opcion):
        dialogo = MDDialog(
            MDDialogHeadlineText(text="Módulo en Desarrollo"),
            MDDialogButtonContainer(
                Widget(),
                MDButton(
                    MDButtonText(text="Entendido"),
                    style="text",
                    on_release=lambda x: dialogo.dismiss()
                ),
            )
        )
        dialogo.open()

    def logout(self):
        app = MDApp.get_running_app()
        app.datos_alumno = None
        
        login_screen = self.manager.get_screen('login')
        login_screen.ids.user_input.text = ""
        login_screen.ids.password_input.text = ""
        
        self.manager.current = 'login'


class StudentInfoScreen(Screen):
    def volver_al_menu(self):
        self.manager.current = 'home'


class PaymentsScreen(Screen):
    def volver_al_menu(self):
        self.manager.current = 'home'

    def cambiar_pestana(self, tabs_instance, tab_item_instance, tab_label_instance):
        valor_tab = tab_item_instance.value
        if valor_tab == "Pendientes":
            self.ids.tabs_manager.current = "screen_pendientes"
        elif valor_tab == "Realizados":
            self.ids.tabs_manager.current = "screen_realizados"


class NotificationsScreen(Screen):
    def volver_al_menu(self):
        self.manager.current = 'home'

    def cambiar_pestana(self, tabs_instance, tab_item_instance, tab_label_instance):
        valor_tab = tab_item_instance.value
        if valor_tab == "NoLeidos":
            self.ids.notifications_tabs_manager.current = "screen_no_leidos"
        elif valor_tab == "Leidos":
            self.ids.notifications_tabs_manager.current = "screen_leidos"

    def mostrar_detalle_comunicado(self, asunto, detalle, id_comunica):
        dialogo = MDDialog(
            MDDialogHeadlineText(text=asunto),
            MDDialogContentContainer(
                MDLabel(
                    text=detalle,
                    font_style="Body",
                    role="medium",
                    theme_text_color="Secondary",
                    adaptive_height=True
                ),
                orientation="vertical"
            ),
            MDDialogButtonContainer(
                Widget(),
                MDButton(
                    MDButtonText(text="CERRAR"),
                    style="text",
                    on_release=lambda x: self.procesar_cierre_comunicado(dialogo, id_comunica)
                ),
            )
        )
        dialogo.open()

    def procesar_cierre_comunicado(self, dialogo, id_comunica):
        dialogo.dismiss()
        if id_comunica is not None:
            database.actualizar_estado_comunicado(id_comunica)
            home_screen = self.manager.get_screen('home')
            home_screen.ir_a_comunicados()


class MainApp(MDApp):
    datos_alumno = None
    
    def build(self):
        self.theme_cls.theme_style = "Light"
        self.theme_cls.primary_palette = "Cyan" 
        return Builder.load_file('colegiodante.kv')
        
if __name__ == '__main__':
    MainApp().run()