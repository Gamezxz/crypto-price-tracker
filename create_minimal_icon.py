#!/usr/bin/env python3
"""
Minimal but professional crypto app icon
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

def create_crypto_icon(size, filename):
    """Create a clean, professional crypto app icon"""
    # Create image
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors - Modern crypto theme
    bg_color = '#0F172A'         # Dark slate
    primary_color = '#3B82F6'    # Blue
    secondary_color = '#F59E0B'  # Amber/Gold
    accent_color = '#10B981'     # Emerald
    
    # Draw main background circle
    margin = max(2, size // 20)
    draw.ellipse([margin, margin, size-margin, size-margin], 
                 fill=bg_color, outline=primary_color, width=max(1, size // 64))
    
    center_x, center_y = size // 2, size // 2
    
    if size >= 64:  # Larger icons - geometric design
        # Draw three circles representing crypto diversity
        circle_size = size // 8
        
        # Positions for three circles
        angle_offset = 2 * math.pi / 3  # 120 degrees apart
        radius_from_center = size // 5
        
        colors = [secondary_color, accent_color, primary_color]
        
        for i in range(3):
            angle = i * angle_offset - math.pi / 2  # Start from top
            x = center_x + radius_from_center * math.cos(angle)
            y = center_y + radius_from_center * math.sin(angle)
            
            # Draw circle
            draw.ellipse([x - circle_size//2, y - circle_size//2,
                         x + circle_size//2, y + circle_size//2],
                        fill=colors[i])
            
            # Draw connecting lines
            if i < 2:  # Don't draw line from last to first
                next_angle = (i + 1) * angle_offset - math.pi / 2
                next_x = center_x + radius_from_center * math.cos(next_angle)
                next_y = center_y + radius_from_center * math.sin(next_angle)
                
                line_width = max(1, size // 128)
                draw.line([(x, y), (next_x, next_y)], 
                         fill=primary_color, width=line_width)
        
        # Close the triangle
        first_angle = -math.pi / 2
        first_x = center_x + radius_from_center * math.cos(first_angle)
        first_y = center_y + radius_from_center * math.sin(first_angle)
        
        last_angle = 2 * angle_offset - math.pi / 2
        last_x = center_x + radius_from_center * math.cos(last_angle)
        last_y = center_y + radius_from_center * math.sin(last_angle)
        
        draw.line([(last_x, last_y), (first_x, first_y)], 
                 fill=primary_color, width=line_width)
        
        # Add center dot
        center_dot_size = size // 20
        draw.ellipse([center_x - center_dot_size, center_y - center_dot_size,
                     center_x + center_dot_size, center_y + center_dot_size],
                    fill=secondary_color)
    
    else:  # Smaller icons - simple design
        # Draw concentric circles
        outer_radius = size // 3
        inner_radius = size // 6
        
        # Outer ring
        draw.ellipse([center_x - outer_radius, center_y - outer_radius,
                     center_x + outer_radius, center_y + outer_radius],
                    outline=secondary_color, width=max(1, size // 32))
        
        # Inner circle
        draw.ellipse([center_x - inner_radius, center_y - inner_radius,
                     center_x + inner_radius, center_y + inner_radius],
                    fill=accent_color)
        
        # Center dot
        dot_size = size // 16
        draw.ellipse([center_x - dot_size, center_y - dot_size,
                     center_x + dot_size, center_y + dot_size],
                    fill=bg_color)
    
    # Add subtle outer glow
    glow_width = max(1, size // 128)
    if glow_width > 0:
        draw.ellipse([1, 1, size-1, size-1], 
                     outline=secondary_color + '40', width=glow_width)
    
    # Save
    img.save(filename, 'PNG')
    print(f"✅ Created: {filename} ({size}x{size})")

def create_contents_json():
    """Create Contents.json file"""
    contents = {
        "images": [
            {"size": "16x16", "idiom": "mac", "filename": "icon_16x16.png", "scale": "1x"},
            {"size": "16x16", "idiom": "mac", "filename": "icon_16x16@2x.png", "scale": "2x"},
            {"size": "32x32", "idiom": "mac", "filename": "icon_32x32.png", "scale": "1x"},
            {"size": "32x32", "idiom": "mac", "filename": "icon_32x32@2x.png", "scale": "2x"},
            {"size": "64x64", "idiom": "mac", "filename": "icon_64x64.png", "scale": "1x"},
            {"size": "64x64", "idiom": "mac", "filename": "icon_64x64@2x.png", "scale": "2x"},
            {"size": "128x128", "idiom": "mac", "filename": "icon_128x128.png", "scale": "1x"},
            {"size": "128x128", "idiom": "mac", "filename": "icon_128x128@2x.png", "scale": "2x"},
            {"size": "256x256", "idiom": "mac", "filename": "icon_256x256.png", "scale": "1x"},
            {"size": "256x256", "idiom": "mac", "filename": "icon_256x256@2x.png", "scale": "2x"},
            {"size": "512x512", "idiom": "mac", "filename": "icon_512x512.png", "scale": "1x"},
            {"size": "512x512", "idiom": "mac", "filename": "icon_512x512@2x.png", "scale": "2x"},
            {"size": "1024x1024", "idiom": "mac", "filename": "icon_1024x1024.png", "scale": "1x"}
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }
    
    import json
    icons_dir = "Assets.xcassets/AppIcon.appiconset"
    with open(f"{icons_dir}/Contents.json", 'w') as f:
        json.dump(contents, f, indent=2)
    print("✅ Created Contents.json")

def main():
    print("🎨 Creating modern Crypto Price Tracker icon...")
    
    # Create directory
    icons_dir = "Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icons_dir, exist_ok=True)
    
    # macOS icon sizes
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    for size in sizes:
        filename = f"{icons_dir}/icon_{size}x{size}.png"
        create_crypto_icon(size, filename)
        
        # @2x versions
        if size <= 512:
            filename_2x = f"{icons_dir}/icon_{size}x{size}@2x.png"
            create_crypto_icon(size * 2, filename_2x)
    
    # Create Contents.json
    create_contents_json()
    
    print("\n🎉 Modern crypto icon complete!")
    print("🔥 Clean geometric design representing crypto diversity!")

if __name__ == "__main__":
    main()