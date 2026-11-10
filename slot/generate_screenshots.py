import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

base_dir = "/Users/manishdubey/Documents/ChatGPT/SaloonOnMap/slot"
customer_out = os.path.join(base_dir, "play_store_assets", "customer_app", "screenshots")
partner_out = os.path.join(base_dir, "play_store_assets", "partner_app", "screenshots")
os.makedirs(customer_out, exist_ok=True)
os.makedirs(partner_out, exist_ok=True)

logo_mark_path = os.path.join(base_dir, "apps", "customer_app", "assets", "images", "slot_logo_mark.jpg")
logo_mark = Image.open(logo_mark_path).convert("RGBA").resize((160, 160), Image.Resampling.LANCZOS)

try:
    font_hero = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 68)
    font_desc = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 36)
    font_card_t = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 40)
    font_card_b = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 30)
    font_pill = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 32)
except:
    font_hero = ImageFont.load_default()
    font_desc = ImageFont.load_default()
    font_card_t = ImageFont.load_default()
    font_card_b = ImageFont.load_default()
    font_pill = ImageFont.load_default()

def create_screenshot(out_path, title, subtitle, bullets, theme_color, bg_gradient_top, bg_gradient_bot, is_partner=False):
    img = Image.new("RGBA", (1080, 1920), bg_gradient_top)
    draw = ImageDraw.Draw(img)
    
    # Gradient Background
    for y in range(1920):
        ratio = y / 1920
        r = int(bg_gradient_top[0] * (1 - ratio) + bg_gradient_bot[0] * ratio)
        g = int(bg_gradient_top[1] * (1 - ratio) + bg_gradient_bot[1] * ratio)
        b = int(bg_gradient_top[2] * (1 - ratio) + bg_gradient_bot[2] * ratio)
        draw.line([(0, y), (1080, y)], fill=(r, g, b))

    # Decorative ambient glow
    glow = Image.new("RGBA", (1080, 1920), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse([540 - 450, 400, 540 + 450, 1300], fill=(theme_color[0], theme_color[1], theme_color[2], 35))
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # Top Brand Header
    brand_name = "SalonOnMap Business" if is_partner else "SalonOnMap"
    draw.text((540, 120), brand_name.upper(), fill=theme_color, font=font_pill, anchor="mm")

    # Main Headline & Subtitle
    draw.text((540, 210), title, fill=(255, 255, 255), font=font_hero, anchor="mm")
    draw.text((540, 280), subtitle, fill=(203, 213, 225), font=font_desc, anchor="mm")

    # Phone Frame Container (Mockup frame)
    frame_x1, frame_y1, frame_x2, frame_y2 = 110, 360, 970, 1820
    draw.rounded_rectangle([frame_x1, frame_y1, frame_x2, frame_y2], radius=60, fill=(15, 23, 42, 240), outline=(51, 65, 85), width=4)
    # Notch / Camera Island
    draw.rounded_rectangle([540 - 120, frame_y1 + 25, 540 + 120, frame_y1 + 60], radius=18, fill=(30, 41, 59))

    # Inner Content Showcase Cards inside frame
    card_y = frame_y1 + 120
    for idx, (head, sub, icon) in enumerate(bullets):
        draw.rounded_rectangle([frame_x1 + 40, card_y, frame_x2 - 40, card_y + 190], radius=28, fill=(30, 41, 59, 230), outline=(theme_color[0], theme_color[1], theme_color[2], 100), width=2)
        # Bullet Icon
        draw.text((frame_x1 + 75, card_y + 50), icon, font=font_card_t)
        draw.text((frame_x1 + 145, card_y + 50), head, fill=(255, 255, 255), font=font_card_t)
        draw.text((frame_x1 + 145, card_y + 105), sub, fill=(148, 163, 184), font=font_card_b)
        card_y += 230

    # Bottom Call to Action inside mockup
    cta_rect = [frame_x1 + 60, frame_y2 - 160, frame_x2 - 60, frame_y2 - 60]
    draw.rounded_rectangle(cta_rect, radius=30, fill=theme_color)
    cta_text = "Manage Your Salon Today" if is_partner else "Book Live Appointment Now"
    draw.text(((frame_x1 + frame_x2)//2, (cta_rect[1] + cta_rect[3])//2), cta_text, fill=(255, 255, 255) if is_partner else (15, 23, 42), font=font_card_t, anchor="mm")

    img.convert("RGB").save(out_path, "PNG")

# 1. Customer Screenshots
create_screenshot(
    os.path.join(customer_out, "1_explore_salons.png"),
    "Explore Salons on Live Map",
    "Find premium stylists & barbers near you in real-time",
    [
        ("Interactive Map View", "Filter by distance, top ratings & services", "📍"),
        ("Live Wait-Time Estimates", "See exact queue and chair availability", "⏱️"),
        ("Verified Customer Reviews", "Authentic photos, ratings and pricing", "⭐"),
        ("Instant Direction Navigation", "One-tap Google Maps route guidance", "🧭"),
    ],
    theme_color=(245, 158, 11),
    bg_gradient_top=(15, 23, 42),
    bg_gradient_bot=(2, 6, 23),
    is_partner=False
)

create_screenshot(
    os.path.join(customer_out, "2_live_seat_booking.png"),
    "Zero Waiting • Live Seat Matrix",
    "Choose your favorite chair, stylist, and time slot",
    [
        ("Real-Time Chair Selection", "Select specific seats and stations live", "💺"),
        ("Stylist Preference", "Pick master barbers or senior hair artists", "✂️"),
        ("Transparent Pricing", "Clear breakdown of services and combos", "💳"),
        ("5-Minute Instant Hold", "Lock your chair while you complete booking", "🔒"),
    ],
    theme_color=(245, 158, 11),
    bg_gradient_top=(15, 23, 42),
    bg_gradient_bot=(2, 6, 23),
    is_partner=False
)

create_screenshot(
    os.path.join(customer_out, "3_ai_style_studio.png"),
    "AI Style Studio Try-On",
    "Preview hairstyles and beard trims before you cut",
    [
        ("Virtual Haircut Try-On", "See trending fade, pompadour or crops on you", "✨"),
        ("Precision Beard Simulation", "Test beard shapes tailored to your face", "🧔"),
        ("Instant Style Sharing", "Share your generated look with your stylist", "📲"),
        ("AI Color & Tone Preview", "Experiment with highlights and rich colors", "🎨"),
    ],
    theme_color=(245, 158, 11),
    bg_gradient_top=(15, 23, 42),
    bg_gradient_bot=(2, 6, 23),
    is_partner=False
)

create_screenshot(
    os.path.join(customer_out, "4_digital_pass.png"),
    "Digital Pass & OTP Check-in",
    "Walk right in and take your chair without queues",
    [
        ("Instant Booking Pass", "Digital appointment card with OTP verification", "🎟️"),
        ("Flexible Payment Modes", "Pay online or directly at the salon counter", "💵"),
        ("Live Appointment Updates", "Push notifications when chair is ready", "🔔"),
        ("Easy Reschedule & Cancel", "Hassle-free 1-tap booking adjustments", "🔄"),
    ],
    theme_color=(245, 158, 11),
    bg_gradient_top=(15, 23, 42),
    bg_gradient_bot=(2, 6, 23),
    is_partner=False
)

# 2. Partner Screenshots
create_screenshot(
    os.path.join(partner_out, "1_operations_dashboard.png"),
    "Real-Time Salon Operations",
    "Complete command center for modern salon owners",
    [
        ("Live Floor Overview", "Monitor all chairs, stylists, and active sessions", "💈"),
        ("Daily Revenue & Footfall", "Real-time tracking of bookings and sales", "📊"),
        ("Instant Booking Alerts", "Audible chime for new incoming appointments", "🔔"),
        ("Quick Actions Hub", "Accept, reschedule or mark appointments complete", "⚡"),
    ],
    theme_color=(16, 185, 129),
    bg_gradient_top=(11, 19, 43),
    bg_gradient_bot=(2, 6, 23),
    is_partner=True
)

create_screenshot(
    os.path.join(partner_out, "2_seat_matrix_queue.png"),
    "Live Seat Matrix & Queue Sync",
    "Synchronize online appointments and walk-in customers",
    [
        ("Interactive Chair Matrix", "Color-coded seat availability: Free, Held, Busy", "💺"),
        ("Walk-in Queue Integration", "Add walk-ins without schedule conflicts", "🚶"),
        ("Anti-Overbooking Locks", "Automatic holds prevent double-seat bookings", "🛡️"),
        ("Floor Layout Customization", "Configure number of chairs and stations", "📐"),
    ],
    theme_color=(16, 185, 129),
    bg_gradient_top=(11, 19, 43),
    bg_gradient_bot=(2, 6, 23),
    is_partner=True
)

create_screenshot(
    os.path.join(partner_out, "3_staff_management.png"),
    "Staff Rostering & Schedules",
    "Empower your stylists and manage working shifts",
    [
        ("Stylist Profiles & Roles", "Assign specialties, experience and service rates", "👥"),
        ("Shift & Break Timing", "Set daily working hours and break schedules", "⏰"),
        ("Commission & Tips Tracking", "Automated breakdown of individual staff earnings", "💰"),
        ("Leave & Holiday Roster", "Prevent booking during staff days off", "📅"),
    ],
    theme_color=(16, 185, 129),
    bg_gradient_top=(11, 19, 43),
    bg_gradient_bot=(2, 6, 23),
    is_partner=True
)

create_screenshot(
    os.path.join(partner_out, "4_analytics_reports.png"),
    "Revenue & Business Insights",
    "Data-driven decisions to scale your salon business",
    [
        ("Daily & Monthly Reports", "Comprehensive revenue, average ticket size & tax", "📈"),
        ("Customer Retention Metrics", "Repeat visit frequency and loyalty trends", "🤝"),
        ("Popular Services Analysis", "Identify top-earning haircuts, spas and treatments", "🏆"),
        ("Direct Bank Payouts", "Fast, automated settlements to your bank account", "🏦"),
    ],
    theme_color=(16, 185, 129),
    bg_gradient_top=(11, 19, 43),
    bg_gradient_bot=(2, 6, 23),
    is_partner=True
)

print("All screenshots generated successfully!")
