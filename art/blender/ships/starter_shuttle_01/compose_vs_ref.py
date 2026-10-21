"""compose_vs_ref.py OUT TITLE REF IMG1 [IMG2 ...] -> side-by-side sheet, labels below each panel.
Labels: pass IMG as path=Label."""
import sys
from PIL import Image, ImageDraw, ImageFont
out,title,*items=sys.argv[1:]
H=760; PAD=24; TOP=70; LAB=60
F="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
f=ImageFont.truetype(F,24); ft=ImageFont.truetype(F,30)
panels=[]
for it in items:
    p,l=(it.split("=",1)+[""])[:2]
    im=Image.open(p).convert("RGB")
    if im.height/im.width < 0.95:  # landscape: fit by width-ish
        pass
    w=int(im.width*H/im.height); panels.append((im.resize((w,H),Image.LANCZOS),l))
W=sum(i.width for i,_ in panels)+PAD*(len(panels)+1)
can=Image.new("RGB",(W,TOP+H+LAB+PAD),(10,14,30)); d=ImageDraw.Draw(can)
d.text((PAD,18),title,fill=(255,255,255),font=ft)
x=PAD
for im,l in panels:
    can.paste(im,(x,TOP)); tw=d.textlength(l,font=f)
    d.text((x+(im.width-tw)/2,TOP+H+14),l,fill=(200,220,255),font=f); x+=im.width+PAD
can.save(out); print(out,can.size)
