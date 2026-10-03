from PIL import Image

def make_transparent(input_path, output_path, fuzz=20):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        # Check if the pixel is white (with some fuzziness)
        if item[0] > 255 - fuzz and item[1] > 255 - fuzz and item[2] > 255 - fuzz:
            new_data.append((255, 255, 255, 0)) # Make transparent
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

make_transparent("assets/images/edp_logo.png", "assets/images/edp_logo_transparent.png", fuzz=20)
