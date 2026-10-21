from pathlib import Path
import argparse
import json
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader
from PIL import Image
from pypdf import PdfReader

parser = argparse.ArgumentParser()
parser.add_argument('--scope', choices=['gameplay', 'cast', 'all'], default='gameplay')
parser.add_argument('--out', required=True)
args = parser.parse_args()

ROOT = Path('/Users/juangonzalezcabello/Main/clicker-band')
V3 = ROOT / 'mockups/2026-10-18-v3-mobile'
V2 = ROOT / 'mockups/2026-10-18-v2'
V1 = ROOT / 'mockups/2026-10-18-v1'
OUT = Path(args.out)
OUT.parent.mkdir(parents=True, exist_ok=True)

font_root = Path('/System/Library/Fonts/Supplemental')
pdfmetrics.registerFont(TTFont('CBText', str(font_root / 'Arial.ttf')))
pdfmetrics.registerFont(TTFont('CBBold', str(font_root / 'Arial Bold.ttf')))
pdfmetrics.registerFont(TTFont('CBDisplay', str(font_root / 'Arial Narrow Bold.ttf')))

BG = HexColor('#12181B')
FG = HexColor('#F8F1DF')
MUTED = HexColor('#ACB3B4')
ACCENT = HexColor('#FFBE49')
LINE = HexColor('#333C40')
W, H = 1200, 675
M = 36

pages = [
    dict(path=V3/'01-cuarto.png', kicker='DE TU CUARTO AL ESTADIO', title='CLICKER BAND',
         sub='Un incremental musical y satírico: forma tu banda, mejora el equipo y gana dinero y fans.',
         footer='01 / TU CUARTO', right='Dinero para mejorar. Fans para abrir puertas.', step=0),
    dict(path=V3/'02-parque.png', kicker='CLICKER BAND', title='ENCUENTRA A LOS TUYOS',
         sub='Un primer público. Un músico que se apunta.',
         footer='02 / EL PARQUE', right='', step=1),
    dict(path=V3/'03-garaje.png', kicker='CLICKER BAND', title='YA SUENA A BANDA',
         sub='Combina músicos, mejora el equipo y prepara el siguiente bolo.',
         footer='03 / EL GARAJE', right='', step=2),
    dict(path=V3/'04-el-sol.png', kicker='CLICKER BAND', title='TU PRIMERA SALA LLENA',
         sub='Del ensayo al escenario de El Sol, Madrid.',
         footer='04 / EL SOL', right='', step=3),
    dict(path=V3/'05-estadio.png', kicker='CLICKER BAND', title='QUE SUENE UNA MÁS',
         sub='Mismo protagonista. Otra escala.',
         footer='05 / EL ESTADIO', right='Y todo empezó con una guitarra.', step=4),
]
if args.scope in ('cast', 'all'):
    pages.extend([
        dict(path=V2/'01-personajes-ds-cd.png', kicker='LOS MÚSICOS', title='TU BANDA, TUS MEZCLAS',
             sub='Caras de la escena. Combinaciones que solo existen aquí.',
             footer='REPARTO / DEPRESIÓN SONORA + CAROLINA DURANTE', right='', step=None, cast=True),
        dict(path=V2/'02-personajes-alcala-norte.png', kicker='LOS MÚSICOS', title='PERSONALIDAD A PRIMERA VISTA',
             sub='Las siluetas de Alcalá Norte también entran en la banda.',
             footer='REPARTO / ALCALÁ NORTE', right='', step=None, cast=True),
    ])
if args.scope == 'all':
    for number, item in enumerate([
        (V1/'01-cuarto.png', 'EL CUARTO', 'Primera exploración de ambiente.'),
        (V1/'02-parque.png', 'EL PARQUE', 'El encuentro con el primer compañero.'),
        (V1/'03-garaje.png', 'EL GARAJE', 'El espacio crece con la banda.'),
        (V1/'04-local-con-ventanas.png', 'POR FIN, VENTANAS', 'Mejor equipo. Mejor local.'),
        (V2/'03-garaje-simplificado.png', 'UN DIBUJO MÁS SENCILLO', 'La dirección visual que dio paso a las pantallas de móvil.'),
    ], start=1):
        pages.append(dict(path=item[0], kicker='EXPLORACIONES ANTERIORES', title=item[1], sub=item[2],
                          footer='BOCETO / ' + str(number).zfill(2), right='', step=None))

doc = canvas.Canvas(str(OUT), pagesize=(W,H), pageCompression=1)
doc.setTitle('Clicker Band - De tu cuarto al estadio')
doc.setAuthor('Clicker Band')
doc.setSubject('Concepto visual de un incremental musical para móvil horizontal')
doc.setCreator('Clicker Band / ReportLab')
doc.setViewerPreference('DisplayDocTitle', 'true')

layout = []
def tracked(text, x, y, size=10, color=ACCENT, tracking=1.4):
    t = doc.beginText(x,y)
    t.setFont('CBBold',size)
    t.setFillColor(color)
    t.setCharSpace(tracking)
    t.textOut(text)
    t.setCharSpace(0)
    doc.drawText(t)

for idx, page in enumerate(pages):
    doc.setFillColor(BG)
    doc.rect(0,0,W,H,fill=1,stroke=0)
    doc.setFillColor(ACCENT)
    doc.rect(M,649,19,3,fill=1,stroke=0)
    tracked(page['kicker'], M+29, 646, 9)
    doc.setFillColor(MUTED)
    doc.setFont('CBText',10)
    doc.drawRightString(W-M,647,f'{idx+1:02d} / {len(pages):02d}')

    title_size = 48 if idx==0 else 40
    assert pdfmetrics.stringWidth(page['title'],'CBDisplay',title_size) <= W-2*M
    doc.setFont('CBDisplay',title_size)
    doc.setFillColor(FG)
    doc.drawString(M,599,page['title'])

    doc.setFont('CBText',13)
    doc.setFillColor(MUTED)
    assert pdfmetrics.stringWidth(page['sub'],'CBText',13) <= W-2*M
    doc.drawString(M,580,page['sub'])

    with Image.open(page['path']) as image:
        iw,ih=image.size
    box_x,box_y,box_w,box_h = M,62,W-2*M,505
    scale=min(box_w/iw,box_h/ih)
    dw,dh=iw*scale,ih*scale
    dx=box_x+(box_w-dw)/2
    dy=box_y+(box_h-dh)/2

    if page.get('cast'):
        doc.setFillColor(HexColor('#DCD4C5'))
        doc.roundRect(box_x,box_y,box_w,box_h,8,fill=1,stroke=0)
    if page.get('cast'):
        pdf_image = ImageReader(str(page['path']))
    else:
        compressed_image = BytesIO()
        with Image.open(page['path']) as source_image:
            source_image.convert('RGB').save(compressed_image,format='JPEG',quality=94,subsampling=0,optimize=True)
        compressed_image.seek(0)
        pdf_image = ImageReader(compressed_image)
    doc.drawImage(pdf_image,dx,dy,width=dw,height=dh,mask='auto')
    if not page.get('cast'):
        doc.setStrokeColor(LINE)
        doc.setLineWidth(0.65)
        doc.rect(dx-0.4,dy-0.4,dw+0.8,dh+0.8,fill=0,stroke=1)

    tracked(page['footer'],M,27,9,color=FG,tracking=0.8)
    if page['right']:
        doc.setFont('CBText',11)
        doc.setFillColor(MUTED)
        doc.drawRightString(W-M,26,page['right'])
    elif page['step'] is not None:
        start=W-M-112
        for j in range(5):
            doc.setFillColor(ACCENT if j<=page['step'] else LINE)
            doc.roundRect(start+j*24,28,16,3,1.5,fill=1,stroke=0)

    doc.bookmarkPage(f'page-{idx+1}')
    doc.addOutlineEntry(page['title'],f'page-{idx+1}',level=0,closed=False)
    layout.append(dict(page=idx+1,source=str(page['path']),image_box=[dx,dy,dw,dh]))
    doc.showPage()

doc.save()
reader=PdfReader(str(OUT))
assert len(reader.pages)==len(pages)
for i,page in enumerate(reader.pages):
    assert (page.extract_text() or '').strip(), f'Missing text on page {i+1}'
Path(str(OUT)+'.layout.json').write_text(json.dumps(layout,ensure_ascii=False,indent=2))
print(json.dumps({'pdf':str(OUT),'pages':len(reader.pages),'size_mb':round(OUT.stat().st_size/1048576,2),'scope':args.scope},ensure_ascii=False))

