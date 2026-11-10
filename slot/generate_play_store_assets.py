import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

base_dir = "/Users/manishdubey/Documents/ChatGPT/SaloonOnMap/slot"
customer_out = os.path.join(base_dir, "play_store_assets", "customer_app")
partner_out = os.path.join(base_dir, "play_store_assets", "partner_app")
os.makedirs(customer_out, exist_ok=True)
os.makedirs(partner_out, exist_ok=True)

logo_mark_path = os.path.join(base_dir, "apps", "customer_app", "assets", "images", "slot_logo_mark.jpg")
logo_path = os.path.join(base_dir, "apps", "customer_app", "assets", "images", "slot_logo.jpg")

logo_mark = Image.open(logo_mark_path).convert("RGBA")

# 1. Generate 512x512 App Icons
icon_cust = logo_mark.resize((512, 512), Image.Resampling.LANCZOS)
icon_cust.save(os.path.join(customer_out, "icon_512.png"), "PNG")

icon_partner = logo_mark.resize((512, 512), Image.Resampling.LANCZOS)
# Add a subtle "BUSINESS" badge on partner icon
draw_p = ImageDraw.Draw(icon_partner)
badge_rect = [0, 440, 512, 512]
draw_p.rectangle(badge_rect, fill=(16, 185, 129, 235))
try:
    font_badge = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 34)
except:
    font_badge = ImageFont.load_default()
draw_p.text((256, 476), "BUSINESS", fill=(255, 255, 255), anchor="mm", font=font_badge)
icon_partner.save(os.path.join(partner_out, "icon_512.png"), "PNG")

# Fonts
try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 64)
    font_subtitle = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 26)
    font_badge = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 20)
    font_pill = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 22)
except:
    font_title = ImageFont.load_default()
    font_subtitle = ImageFont.load_default()
    font_badge = ImageFont.load_default()
    font_pill = ImageFont.load_default()

# 2. Customer Feature Graphic (1024 x 500)
fg_cust = Image.new("RGBA", (1024, 500), (15, 23, 42, 255))
# Gradient effect
for y in range(500):
    r = int(15 + (30 - 15) * (y / 500))
    g = int(23 + (41 - 23) * (y / 500))
    b = int(42 + (68 - 42) * (y / 500))
    for x in range(1024):
        pass # Draw row
draw_fg_c = ImageDraw.Draw(fg_cust)

# Glow orbs
glow = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
glow_draw.ellipse([700, -50, 1100, 350], fill=(217, 119, 6, 60))
glow_draw.ellipse([50, 250, 450, 650], fill=(245, 158, 11, 40))
glow = glow.filter(ImageFilter.GaussianBlur(50))
fg_cust = Image.alpha_composite(fg_cust, glow)
draw_fg_c = ImageDraw.Draw(fg_cust)

# Logo placement
logo_small = logo_mark.resize((260, 260), Image.Resampling.LANCZOS)
# Circular mask for logo
mask = Image.new("L", (260, 260), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, 260, 260], radius=52, fill=255)
fg_cust.paste(logo_small, (690, 120), mask)

# Border around logo
draw_fg_c.rounded_rectangle([690, 120, 950, 380], radius=52, outline=(245, 158, 11, 180), width=3)

# Text elements
draw_fg_c.text((80, 120), "SalonOnMap", fill=(255, 255, 255), font=font_title)
draw_fg_c.text((80, 205), "DISCOVER • BOOK LIVE SEATS • ZERO WAITING", fill=(245, 158, 11), font=font_subtitle)
draw_fg_c.text((80, 255), "Book top-rated salons, stylists & spas near you instantly.", fill=(203, 213, 225), font=font_badge)

# Feature Badges
pills = ["📍 Real-Time Map", "💺 Live Seat Booking", "✨ AI Style Studio"]
px = 80
for pill in pills:
    bbox = draw_fg_c.textbbox((px + 16, 335), pill, font=font_pill)
    draw_fg_c.rounded_rectangle([px, 325, bbox[2] + 16, 365], radius=20, fill=(30, 41, 59, 230), outline=(245, 158, 11, 120), width=1)
    draw_fg_c.text((px + 16, 335), pill, fill=(255, 255, 255), font=font_pill)
    px = bbox[2] + 32

fg_cust.convert("RGB").save(os.path.join(customer_out, "feature_graphic_1024x500.png"), "PNG")


# 3. Partner Feature Graphic (1024 x 500)
fg_part = Image.new("RGBA", (1024, 500), (11, 19, 43, 255))
glow_p = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
glow_draw_p = ImageDraw.Draw(glow_p)
glow_draw_p.ellipse([700, -50, 1100, 350], fill=(16, 185, 129, 65))
glow_draw_p.ellipse([50, 250, 450, 650], fill=(6, 182, 212, 45))
glow_p = glow_p.filter(ImageFilter.GaussianBlur(50))
fg_part = Image.alpha_composite(fg_part, glow_p)
draw_fg_p = ImageDraw.Draw(fg_part)

# Logo
fg_part.paste(logo_small, (690, 120), mask)
draw_fg_p.rounded_rectangle([690, 120, 950, 380], radius=52, outline=(16, 185, 129, 180), width=3)

# Text elements
draw_fg_p.text((80, 110), "SalonOnMap", fill=(255, 255, 255), font=font_title)
draw_fg_p.text((80, 180), "BUSINESS", fill=(16, 185, 129), font=font_title)
draw_fg_p.text((80, 260), "GROW YOUR SALON • MANAGE SEATS & QUEUES", fill=(52, 211, 153), font=font_subtitle)
draw_fg_p.text((80, 305), "Live chair matrix, staff rosters, walk-in sync & instant payouts.", fill=(203, 213, 225), font=font_badge)

# Feature Badges
pills_p = ["📊 Seat Matrix", "👥 Staff Rostering", "📈 Daily Analytics"]
px = 80
for pill in pills_p:
    bbox = draw_fg_p.textbbox((px + 16, 375), pill, font=font_pill)
    draw_fg_p.rounded_rectangle([px, 365, bbox[2] + 16, 405], radius=20, fill=(28, 37, 65, 230), outline=(16, 185, 129, 120), width=1)
    draw_fg_p.text((px + 16, 375), pill, fill=(255, 255, 255), font=font_pill)
    px = bbox[2] + 32

fg_part.convert("RGB").save(os.path.join(partner_out, "feature_graphic_1024x500.png"), "PNG")

print("Graphics generated successfully!")
