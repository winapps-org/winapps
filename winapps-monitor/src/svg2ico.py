# conda install pillow
# conda install -c conda-forge cairosvg
from PIL import Image
import io
import cairosvg

# File Paths
svg_path = "../assets/icons/system_tray_icon.svg"
ico_path = "../assets/icons/system_tray_icon.ico"

# Convert SVG file to PNG bytes
with open(svg_path, "rb") as f:
    svg_data = f.read()
png_bytes = cairosvg.svg2png(bytestring=svg_data, output_width=256, output_height=256)

# Open PNG bytes as Pillow image
image = Image.open(io.BytesIO(png_bytes))

# Save as ICO with multiple sizes
image.save(ico_path, format="ICO", sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
