from http.server import HTTPServer, SimpleHTTPRequestHandler

class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            html = '''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Textil - Plan de Implementacion</title>
<style>
body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;max-width:900px;margin:0 auto;padding:2rem;background:#0f0f1a;color:#e0e0e0;line-height:1.7}
h1{color:#fff;font-size:2rem;text-align:center;margin-bottom:0.5rem}
p.sub{text-align:center;color:#8b8ba0;margin-bottom:2rem}
.card{background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.08);border-radius:12px;padding:1.5rem;margin-bottom:1.5rem}
.card h2{color:#a5b4fc;font-size:1.1rem;margin:0 0 1rem 0}
.stat{display:inline-block;text-align:center;margin:0 1.5rem 1rem 0}
.stat .num{display:block;font-size:2rem;font-weight:700;color:#818cf8}
.stat .lbl{font-size:0.85rem;color:#8b8ba0}
.badge{display:inline-block;background:rgba(99,102,241,0.15);border:1px solid rgba(99,102,241,0.3);border-radius:999px;padding:0.3rem 0.8rem;font-size:0.85rem;color:#a5b4fc;margin:0.25rem}
</style>
</head>
<body>
<h1>Textil</h1>
<p class="sub">Plan de Implementacion - App Movil React Native / Expo</p>
<div class="card">
<h2>Proyecto Actual (SwiftUI)</h2>
<div class="stat"><span class="num">176</span><span class="lbl">Archivos Swift</span></div>
<div class="stat"><span class="num">25,190</span><span class="lbl">Lineas de codigo</span></div>
<div class="stat"><span class="num">64</span><span class="lbl">Modelos</span></div>
<div class="stat"><span class="num">94</span><span class="lbl">Vistas</span></div>
<div class="stat"><span class="num">3</span><span class="lbl">Tablas Supabase</span></div>
</div>
<div class="card">
<h2>Fase 1 - Estimacion: 32 horas</h2>
<p>Login, Autenticacion, Gestion de Usuarios y Roles</p>
<div style="margin-top:1rem">
<span class="badge">E1: Config proyecto (2h)</span>
<span class="badge">E2: Login (3h)</span>
<span class="badge">E3: Auth Context (4h)</span>
<span class="badge">E4: Bloqueado/Pendiente (2h)</span>
<span class="badge">E5: Navegacion (4h)</span>
<span class="badge">E6: Perfil (2h)</span>
<span class="badge">E7: Gestion Usuarios (6h)</span>
<span class="badge">E8: Gestion Roles (4h)</span>
<span class="badge">E9: Pruebas (4h)</span>
<span class="badge">E10: Documentacion (1h)</span>
</div>
</div>
<div class="card">
<h2>Documento completo</h2>
<p>Abre el archivo <code>PLAN_IMPLEMENTACION.md</code> en el editor para ver el plan detallado con todos los entregables, estimaciones y estructura propuesta.</p>
</div>
</body>
</html>'''
            self.wfile.write(html.encode())
        else:
            super().do_GET()

if __name__ == '__main__':
    HTTPServer(('0.0.0.0', 5000), Handler).serve_forever()
