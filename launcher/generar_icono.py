from PIL import Image, ImageDraw

TRAZO = (237, 236, 232, 255)
FONDO = (30, 30, 33, 255)
SS = 4
LADO = 1024 * SS


def bezier(p0, p1, p2, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0]
        y = u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


def generar(salida, ancho_destino, fondo):
    img = Image.new("RGBA", (LADO, LADO), fondo if fondo else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    escala = (ancho_destino * SS) / 520.0
    alto_destino = 460 * escala
    ox = (LADO - 520 * escala) / 2
    oy = (LADO - alto_destino) / 2

    def T(x, y):
        return (x * escala + ox, y * escala + oy)

    def w(v):
        return max(1, int(round(v * escala)))

    def linea_redonda(puntos, grosor):
        pts = [T(*p) for p in puntos]
        d.line(pts, fill=TRAZO, width=grosor, joint="curve")
        r = grosor / 2
        for p in (pts[0], pts[-1]):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=TRAZO)

    def rect_redondo(x, y, an, al, rad, grosor):
        x0, y0 = T(x, y)
        x1, y1 = T(x + an, y + al)
        d.rounded_rectangle(
            [x0, y0, x1, y1], radius=rad * escala, outline=TRAZO, width=grosor
        )

    def circulo(cx, cy, r, grosor=None, relleno=False):
        c = T(cx, cy)
        rr = r * escala
        bbox = [c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr]
        if relleno:
            d.ellipse(bbox, fill=TRAZO)
        else:
            d.ellipse(bbox, outline=TRAZO, width=grosor)

    rect_redondo(292, 20, 36, 44, 12, w(15))
    rect_redondo(477, 211, 20, 36, 8, w(12))
    circulo(310, 242, 170, grosor=w(15))
    linea_redonda([(310, 242), (213, 183)], w(15))
    linea_redonda([(310, 242), (350, 173)], w(15))
    circulo(310, 242, 15, relleno=True)
    circulo(50, 156, 11, relleno=True)
    linea_redonda([(66, 179), (136, 179)], w(15))
    linea_redonda([(14, 212), (138, 212)], w(15))
    linea_redonda([(22, 244), (138, 244)], w(15))
    linea_redonda([(38, 274), (134, 274)], w(15))
    linea_redonda(bezier((167, 394), (98, 378), (66, 341)), w(15))
    linea_redonda(bezier((150, 413), (70, 396), (34, 358)), w(15))

    img = img.resize((1024, 1024), Image.LANCZOS)
    img.save(salida)
    print("OK", salida)


generar("icono.png", 720, FONDO)
generar("icono_foreground.png", 560, None)
