from typing import Dict, Any, List, Tuple
from PIL import Image, ImageDraw, ImageFont


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = (
        [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        ]
        if bold
        else [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ]
    )
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue
    return ImageFont.load_default()


def _hex_to_rgb(hex_str: str) -> Tuple[int, int, int]:
    h = hex_str.lstrip("#")
    if len(h) == 6:
        return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return (40, 62, 93)


def _wrap_text(draw: ImageDraw.ImageDraw, text: str, font: Any, max_w: int) -> List[str]:
    words = text.split()
    lines: List[str] = []
    cur = ""
    for w in words:
        test = f"{cur} {w}".strip()
        bbox = draw.textbbox((0, 0), test, font=font)
        if (bbox[2] - bbox[0]) <= max_w or not cur:
            cur = test
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


class StoryboardRenderer:
    """
    Dynamically renders a personalized multi-card Hairstyle & Beard Storyboard Sheet
    using only the customer's generated portraits and dynamic analysis/recommendation metadata.
    Zero static template images are used.
    """

    def render_storyboard(
        self,
        portraits: List[Image.Image],
        options: List[Dict[str, Any]],
        best_option: Dict[str, Any],
        barber_notes: List[str],
        analysis: Dict[str, Any],
    ) -> Image.Image:
        n_cards = len(options)
        cols = 3 if n_cards >= 3 else max(1, n_cards)
        rows = (n_cards + cols - 1) // cols

        canvas_w = 1200
        header_h = 84
        card_h = 540
        row_gap = 20
        footer_h = 215
        canvas_h = header_h + rows * card_h + (rows - 1) * row_gap + footer_h + 28

        board = Image.new("RGB", (canvas_w, canvas_h), (245, 241, 234))
        draw = ImageDraw.Draw(board)

        f_title = _load_font(26, bold=True)
        f_sub = _load_font(14, bold=False)
        f_card_hdr = _load_font(16, bold=True)
        f_badge = _load_font(12, bold=True)
        f_bold = _load_font(13, bold=True)
        f_body = _load_font(13, bold=False)
        f_footer_hdr = _load_font(17, bold=True)

        # Top Banner
        face_shape = (
            analysis.get("face_geometry", {}).get("estimated_face_shape", "balanced").replace("_", " ").title()
        )
        hair_tex = (
            analysis.get("hair_analysis", {}).get("visible_texture", "natural").replace("_", " ").title()
        )
        banner_title = "PERSONALIZED HAIRSTYLE & BEARD SUGGESTIONS"
        banner_sub = (
            f"Tailored to Your Uploaded Portrait  •  Estimated Proportions: {face_shape}  •  "
            f"Detected Hair Texture: {hair_tex}"
        )

        tb = draw.textbbox((0, 0), banner_title, font=f_title)
        draw.text(((canvas_w - (tb[2] - tb[0])) // 2, 16), banner_title, fill=(28, 37, 54), font=f_title)
        sb = draw.textbbox((0, 0), banner_sub, font=f_sub)
        draw.text(((canvas_w - (sb[2] - sb[0])) // 2, 50), banner_sub, fill=(92, 100, 115), font=f_sub)

        margin_x = 24
        col_gap = 18
        card_w = (canvas_w - 2 * margin_x - (cols - 1) * col_gap) // cols

        for idx, opt in enumerate(options):
            r = idx // cols
            c = idx % cols
            x0 = margin_x + c * (card_w + col_gap)
            y0 = header_h + r * (card_h + row_gap)
            x1 = x0 + card_w
            y1 = y0 + card_h

            is_rec = bool(opt.get("is_recommended"))
            border_col = (212, 160, 36) if is_rec else (214, 208, 198)
            border_w = 3 if is_rec else 2

            draw.rounded_rectangle([x0, y0, x1, y1], radius=14, fill=(252, 250, 246), outline=border_col, width=border_w)

            hdr_rgb = _hex_to_rgb(opt.get("header_hex", "#283E5D"))
            draw.rounded_rectangle([x0, y0, x1, y0 + 44], radius=14, fill=hdr_rgb)
            draw.rectangle([x0, y0 + 28, x1, y0 + 44], fill=hdr_rgb)

            opt_num = opt.get("option_number", idx + 1)
            hdr_text = f"{opt_num}. {opt.get('title', '')}"
            if len(hdr_text) > 36:
                hdr_text = hdr_text[:34] + "…"
            draw.text((x0 + 14, y0 + 12), hdr_text, fill=(255, 255, 255), font=f_card_hdr)

            # Portrait image
            p_img = portraits[idx]
            pw = card_w - 24
            ph = 315
            p_resized = p_img.resize((pw, ph), Image.Resampling.LANCZOS)
            board.paste(p_resized, (x0 + 12, y0 + 52))
            draw.rectangle([x0 + 12, y0 + 52, x0 + 12 + pw, y0 + 52 + ph], outline=(224, 218, 208), width=1)

            # Score & Best Match Badge
            score = opt.get("suitability_score", 90)
            badge_txt = f"TOP MATCH • {score}%" if is_rec else f"Match {score}%"
            badge_bg = (212, 160, 36) if is_rec else (38, 52, 74)
            bb = draw.textbbox((0, 0), badge_txt, font=f_badge)
            bw = (bb[2] - bb[0]) + 16
            draw.rounded_rectangle(
                [x1 - 18 - bw, y0 + 60, x1 - 18, y0 + 84], radius=6, fill=badge_bg
            )
            draw.text((x1 - 10 - bw, y0 + 65), badge_txt, fill=(255, 255, 255), font=f_badge)

            # Metadata bullets below portrait
            ty = y0 + 376
            max_tw = card_w - 28
            bullets = [
                ("Hair:", f"{opt.get('hair_length_cm', '')} — {opt.get('hair_desc', '')}"),
                ("Beard:", f"{opt.get('beard_length_mm', '')} — {opt.get('beard_desc', '')}"),
                ("Why it fits:", opt.get("why_it_suits", "")),
            ]
            for label, val in bullets:
                if ty > y1 - 24:
                    break
                draw.text((x0 + 14, ty), f"• {label}", fill=(30, 41, 59), font=f_bold)
                lb_w = draw.textbbox((0, 0), f"• {label} ", font=f_bold)[2]
                wrapped = _wrap_text(draw, val, f_body, max_tw - lb_w)
                if wrapped:
                    draw.text((x0 + 14 + lb_w, ty), wrapped[0], fill=(65, 75, 90), font=f_body)
                    ty += 18
                    for extra_line in wrapped[1:2]:
                        if ty <= y1 - 20:
                            draw.text((x0 + 24, ty), extra_line, fill=(65, 75, 90), font=f_body)
                            ty += 17

        # Footer Row: Left = Barber Notes, Right = Best Option For You Card
        fy0 = header_h + rows * card_h + (rows - 1) * row_gap + 16
        fy1 = canvas_h - 16
        left_w = int((canvas_w - 2 * margin_x - col_gap) * 0.62)
        right_x0 = margin_x + left_w + col_gap

        # Left Panel: Key Styling Notes for Your Barber
        draw.rounded_rectangle(
            [margin_x, fy0, margin_x + left_w, fy1],
            radius=12,
            fill=(252, 250, 246),
            outline=(214, 208, 198),
            width=2,
        )
        draw.rounded_rectangle(
            [margin_x, fy0, margin_x + left_w, fy0 + 38],
            radius=12,
            fill=(40, 62, 93),
        )
        draw.rectangle([margin_x, fy0 + 24, margin_x + left_w, fy0 + 38], fill=(40, 62, 93))
        draw.text((margin_x + 16, fy0 + 10), "Key Styling Notes for Your Barber", fill=(255, 255, 255), font=f_footer_hdr)

        ny = fy0 + 48
        for note in barber_notes[:4]:
            lines = _wrap_text(draw, f"• {note}", f_body, left_w - 32)
            for ln in lines[:2]:
                if ny <= fy1 - 18:
                    draw.text((margin_x + 16, ny), ln, fill=(45, 55, 72), font=f_body)
                    ny += 18
            ny += 4

        # Right Panel: Best Option For You
        draw.rounded_rectangle(
            [right_x0, fy0, canvas_w - margin_x, fy1],
            radius=12,
            fill=(253, 248, 235),
            outline=(212, 160, 36),
            width=2,
        )
        draw.rounded_rectangle(
            [right_x0, fy0, canvas_w - margin_x, fy0 + 38],
            radius=12,
            fill=(180, 128, 24),
        )
        draw.rectangle([right_x0, fy0 + 24, canvas_w - margin_x, fy0 + 38], fill=(180, 128, 24))
        draw.text((right_x0 + 16, fy0 + 10), "Best Option For You (Top Recommendation)", fill=(255, 255, 255), font=f_footer_hdr)

        right_w = (canvas_w - margin_x) - right_x0
        by = fy0 + 50
        best_title = best_option.get("title", "Option 1")
        for ln in _wrap_text(draw, best_title, f_card_hdr, right_w - 32)[:2]:
            draw.text((right_x0 + 16, by), ln, fill=(28, 37, 54), font=f_card_hdr)
            by += 22

        by += 4
        best_reason = best_option.get("reason", "")
        for ln in _wrap_text(draw, best_reason, f_body, right_w - 32)[:4]:
            if by <= fy1 - 18:
                draw.text((right_x0 + 16, by), ln, fill=(65, 75, 90), font=f_body)
                by += 18

        return board
