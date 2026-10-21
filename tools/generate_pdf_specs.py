import pymupdf
import shutil

doc = pymupdf.open()
rect = pymupdf.Rect(36, 36, 559, 806)

html_p1 = """
<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    color: #1e293b;
    margin: 0;
    padding: 0;
    font-size: 9pt;
    line-height: 1.35;
  }
  .header {
    background-color: #28208C;
    color: white;
    padding: 16px 22px;
    border-radius: 8px;
    margin-bottom: 12px;
  }
  .header h1 {
    margin: 0 0 4px 0;
    font-size: 17pt;
    font-weight: 800;
    letter-spacing: -0.5px;
    color: #ffffff;
  }
  .header p {
    margin: 0;
    font-size: 8.5pt;
    color: #e2d6f5;
  }
  .badge {
    display: inline-block;
    background-color: #6B1C9B;
    color: #ffffff;
    font-size: 7.5pt;
    font-weight: 700;
    padding: 2px 8px;
    border-radius: 4px;
    margin-top: 6px;
    text-transform: uppercase;
  }
  h2 {
    color: #28208C;
    font-size: 10.5pt;
    border-bottom: 2px solid #e2e8f0;
    padding-bottom: 3px;
    margin-top: 10px;
    margin-bottom: 6px;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 8px;
  }
  th {
    background-color: #f1f5f9;
    color: #334155;
    font-weight: 700;
    font-size: 7.5pt;
    text-align: left;
    padding: 5px 7px;
    border: 1px solid #cbd5e1;
  }
  td {
    padding: 4px 7px;
    font-size: 7.5pt;
    border: 1px solid #e2e8f0;
    vertical-align: top;
  }
  tr:nth-child(even) td {
    background-color: #f8fafc;
  }
  .highlight {
    font-weight: 700;
    color: #6B1C9B;
  }
  .tag {
    display: inline-block;
    font-size: 6.5pt;
    font-weight: 700;
    padding: 1px 5px;
    border-radius: 3px;
    margin-left: 4px;
    text-transform: uppercase;
  }
  .tag-fold { background: #ede9fe; color: #5b21b6; }
  .tag-flip { background: #fce7f3; color: #9d174d; }
  .note-box {
    background-color: #faf5ff;
    border-left: 4px solid #6B1C9B;
    padding: 7px 10px;
    margin: 6px 0 8px 0;
    font-size: 7.5pt;
    color: #4a044e;
    border-radius: 0 5px 5px 0;
  }
  .footer {
    text-align: center;
    font-size: 7pt;
    color: #94a3b8;
    margin-top: 10px;
    border-top: 1px solid #e2e8f0;
    padding-top: 4px;
  }
</style>
</head>
<body>

<div class='header'>
  <h1>ARTIST DUBAI</h1>
  <p>Master Graphic &amp; Display Specifications — Mobile, Tablet, Foldables &amp; Flips</p>
  <span class='badge'>Complete Hardware Support • Fold / Flip / Phone / Tablet / Store</span>
</div>

<h2>1. App Store &amp; Launch Icons</h2>
<table>
  <tr>
    <th style='width: 30%;'>Asset Type</th>
    <th style='width: 20%;'>Dimensions</th>
    <th style='width: 14%;'>Format</th>
    <th style='width: 36%;'>Design &amp; Safe-Zone Rules</th>
  </tr>
  <tr>
    <td><b>App Master Icon</b><br><span style='color: #64748B;'>iOS App Store &amp; Google Play</span></td>
    <td><span class='highlight'>1024 × 1024 px</span></td>
    <td>PNG (Opaque)</td>
    <td>No alpha transparency. Center artwork inside 820×820 px circle to avoid store corner mask cuts.</td>
  </tr>
  <tr>
    <td><b>Adaptive Foreground</b><br><span style='color: #64748B;'>Android 8.0+ Icon Layer</span></td>
    <td><span class='highlight'>1024 × 1024 px</span></td>
    <td>PNG (Alpha)</td>
    <td>Transparent background. Keep artwork within inner 680×680 px circle (outer 172 px margin gets dynamically masked).</td>
  </tr>
  <tr>
    <td><b>Adaptive Background</b><br><span style='color: #64748B;'>Android 8.0+ Icon Layer</span></td>
    <td><span class='highlight'>1024 × 1024 px</span></td>
    <td>PNG / Solid</td>
    <td>Solid brand color (#28208C) or subtle branded geometric gradient.</td>
  </tr>
  <tr>
    <td><b>Top Bar Header Logo</b><br><span style='color: #64748B;'>Rendered at 40-50 dp height</span></td>
    <td><span class='highlight'>1024 × 1024 px</span><br>(Min: 512×512)</td>
    <td>PNG (Alpha)</td>
    <td>1:1 Square transparent PNG. Crisp vector silhouette with ~5% margin.</td>
  </tr>
</table>

<h2>2. Foldable &amp; Flip Phone Display Specifications</h2>
<table>
  <tr>
    <th style='width: 30%;'>Device Screen State</th>
    <th style='width: 22%;'>Dimensions</th>
    <th style='width: 14%;'>Ratio</th>
    <th style='width: 34%;'>Hardware Examples &amp; Guidance</th>
  </tr>
  <tr>
    <td><b>Fold Outer Cover Screen</b><span class='tag tag-fold'>Fold Closed</span><br><span style='color: #64748B;'>Ultra-tall narrow form factor</span></td>
    <td><span class='highlight'>1080 × 2520 px</span><br>(or 904 × 2316)</td>
    <td>21:9 to 23:9</td>
    <td>Samsung Galaxy Z Fold 4/5/6, Google Pixel Fold (Cover), OnePlus Open (Cover).</td>
  </tr>
  <tr>
    <td><b>Fold Inner Main Screen</b><span class='tag tag-fold'>Fold Open</span><br><span style='color: #64748B;'>Tablet-like square canvas</span></td>
    <td><span class='highlight'>2176 × 1812 px</span><br>(or 2208 × 1768)</td>
    <td>~1.2:1 (6:5)</td>
    <td>Galaxy Z Fold 5/6, Pixel Fold, OnePlus Open unfolded. Massive square viewing area.</td>
  </tr>
  <tr>
    <td><b>Flip Inner Main Screen</b><span class='tag tag-flip'>Flip Open</span><br><span style='color: #64748B;'>Ultra-tall cinematic display</span></td>
    <td><span class='highlight'>1080 × 2640 px</span></td>
    <td>22:9</td>
    <td>Samsung Galaxy Z Flip 4/5/6, Motorola Razr 40/50 Ultra. Long vertical scroll layout.</td>
  </tr>
  <tr>
    <td><b>Flip Outer Flex Window</b><span class='tag tag-flip'>Flip Cover</span><br><span style='color: #64748B;'>External cover preview screen</span></td>
    <td><span class='highlight'>720 × 748 px</span><br>(or 1056 × 1066)</td>
    <td>~1:1 (Square)</td>
    <td>Galaxy Z Flip 5/6 (3.4-inch Flex Window), Moto Razr Ultra external screen widgets.</td>
  </tr>
</table>

<div class='note-box'>
  <b>FOLD &amp; FLIP DESIGN SAFE ZONE:</b> For Fold &amp; Flip screens, keep primary typography, logos, and critical messaging centered inside a <b>700 × 700 px</b> safe square. The background illustration must extend fully edge-to-edge so transitioning between folded (closed) and unfolded (open) states remains perfectly seamless without jarring content jumps.
</div>

<div class='footer'>Page 1 of 2 — Artist Dubai Production Graphics Specifications</div>

</body>
</html>
"""

html_p2 = """
<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    color: #1e293b;
    margin: 0;
    padding: 0;
    font-size: 9pt;
    line-height: 1.35;
  }
  .sub-header {
    background-color: #f8fafc;
    border-left: 4px solid #28208C;
    padding: 8px 14px;
    margin-bottom: 10px;
  }
  .sub-header h2 {
    margin: 0;
    font-size: 12pt;
    color: #28208C;
    border: none;
    padding: 0;
  }
  .sub-header p {
    margin: 2px 0 0 0;
    font-size: 8pt;
    color: #64748b;
  }
  h3 {
    color: #28208C;
    font-size: 9.5pt;
    border-bottom: 2px solid #e2e8f0;
    padding-bottom: 2px;
    margin-top: 10px;
    margin-bottom: 5px;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 8px;
  }
  th {
    background-color: #f1f5f9;
    color: #334155;
    font-weight: 700;
    font-size: 7.5pt;
    text-align: left;
    padding: 5px 7px;
    border: 1px solid #cbd5e1;
  }
  td {
    padding: 4px 7px;
    font-size: 7.5pt;
    border: 1px solid #e2e8f0;
    vertical-align: top;
  }
  tr:nth-child(even) td {
    background-color: #f8fafc;
  }
  .highlight {
    font-weight: 700;
    color: #6B1C9B;
  }
  .checklist {
    background-color: #f0fdf4;
    border: 1px solid #bbf7d0;
    border-radius: 6px;
    padding: 8px 12px;
    margin-top: 8px;
  }
  .checklist h4 {
    margin: 0 0 4px 0;
    color: #166534;
    font-size: 8.5pt;
  }
  .checklist ul {
    margin: 0;
    padding-left: 16px;
    font-size: 7.5pt;
    color: #15803d;
  }
  .checklist li {
    margin-bottom: 2px;
  }
  .swatch {
    border: 1px solid #cbd5e1;
    border-radius: 4px;
    padding: 3px 6px;
    font-size: 7pt;
    background: #ffffff;
    display: inline-block;
    margin-right: 6px;
  }
  .footer {
    text-align: center;
    font-size: 7pt;
    color: #94a3b8;
    margin-top: 10px;
    border-top: 1px solid #e2e8f0;
    padding-top: 4px;
  }
</style>
</head>
<body>

<div class='sub-header'>
  <h2>STANDARD PHONES, TABLETS &amp; IN-APP ASSETS</h2>
  <p>Standard Mobile, Tablets, Dashboard Matrix &amp; Content Guidelines</p>
</div>

<h3>3. Standard Mobile, Tablet &amp; Desktop Splash Screens</h3>
<table>
  <tr>
    <th style='width: 32%;'>Screen Target</th>
    <th style='width: 20%;'>Dimensions</th>
    <th style='width: 14%;'>Ratio</th>
    <th style='width: 34%;'>Hardware Examples</th>
  </tr>
  <tr>
    <td><b>Tall Modern Flagship</b></td>
    <td><span class='highlight'>1080 × 2400 px</span></td>
    <td>9:20</td>
    <td>iPhone 14/15/16 Pro Max, Samsung Galaxy S23/S24+</td>
  </tr>
  <tr>
    <td><b>Standard Universal Phone</b></td>
    <td><span class='highlight'>1080 × 1920 px</span></td>
    <td>9:16</td>
    <td>Standard Android / iPhone SE / Universal base</td>
  </tr>
  <tr>
    <td><b>Tablet / iPad (Portrait)</b></td>
    <td><span class='highlight'>1600 × 2400 px</span></td>
    <td>2:3 (4:3)</td>
    <td>iPad Pro 11-in / 12.9-in, iPad Air, Galaxy Tab S9 (Portrait)</td>
  </tr>
  <tr>
    <td><b>Tablet / Desktop (Landscape)</b></td>
    <td><span class='highlight'>2400 × 1600 px</span></td>
    <td>3:2 (16:10)</td>
    <td>Landscape iPads, Galaxy Tab Ultra, Desktop Web</td>
  </tr>
</table>

<h3>4. Dashboard Grid &amp; Category Explorer</h3>
<table>
  <tr>
    <th style='width: 32%;'>Asset Type</th>
    <th style='width: 20%;'>Dimensions</th>
    <th style='width: 14%;'>Format</th>
    <th style='width: 34%;'>Usage Location</th>
  </tr>
  <tr>
    <td><b>3D Dashboard Icons</b><br><span style='color: #64748B;'>8 Core Functional Tiles</span></td>
    <td><span class='highlight'>512 × 512 px</span><br>(or 1024×1024)</td>
    <td>PNG (Alpha)</td>
    <td>Artists, Galleries, Events &amp; Competition, Photos, Government, About Us, Registrations.</td>
  </tr>
  <tr>
    <td><b>Card Background Covers</b><br><span style='color: #64748B;'>1:1 Square Card Art</span></td>
    <td><span class='highlight'>600 × 600 px</span><br>(Min: 512×512)</td>
    <td>JPG / WebP</td>
    <td>Dashboard card photographic backgrounds with subtle dark vignette.</td>
  </tr>
  <tr>
    <td><b>Category Banners</b></td>
    <td><span class='highlight'>800 × 450 px</span></td>
    <td>16:9</td>
    <td>Category detail hero banners and promotional cards.</td>
  </tr>
</table>

<h3>5. Content Uploads &amp; Profile Standards</h3>
<table>
  <tr>
    <th style='width: 32%;'>Content Type</th>
    <th style='width: 20%;'>Recommended</th>
    <th style='width: 14%;'>Ratio</th>
    <th style='width: 34%;'>Notes &amp; Optimization</th>
  </tr>
  <tr>
    <td><b>Event Poster / Banner</b></td>
    <td><span class='highlight'>1200 × 675 px</span></td>
    <td>16:9</td>
    <td>Max 350 KB. Event detail cover &amp; calendar listings.</td>
  </tr>
  <tr>
    <td><b>Artist / Gallery Avatar</b></td>
    <td><span class='highlight'>512 × 512 px</span></td>
    <td>1:1 (Square)</td>
    <td>Max 150 KB. Circular crop safe in UI. Center facial/brand focus.</td>
  </tr>
  <tr>
    <td><b>Artwork Showcase</b></td>
    <td><span class='highlight'>1200 × 1200 px</span></td>
    <td>1:1 or 4:3</td>
    <td>Max 400 KB. High fidelity art showcase portfolio.</td>
  </tr>
  <tr>
    <td><b>Competition / Photos</b></td>
    <td><span class='highlight'>1920 × 1080 px</span></td>
    <td>16:9 / 3:2</td>
    <td>Max 500 KB. Photo exhibitions and competition galleries.</td>
  </tr>
</table>

<div class='checklist'>
  <h4>Designer Export &amp; Technical Checklist:</h4>
  <ul>
    <li><b>Color Space:</b> Always export in <b>sRGB</b> (Avoid CMYK or Display P3 which wash out or invert on Android/iOS).</li>
    <li><b>Resolution / DPI:</b> <b>72 DPI</b> (screen resolution). All pixel dimensions above are physical 1:1 render sizes.</li>
    <li><b>File Size Limits:</b> Icons &amp; Logos &lt; 150 KB • Backgrounds &lt; 1.2 MB • Photos &lt; 350 KB.</li>
    <li><b>Brand Colors:</b>
      <span class='swatch'><b style='color:#28208C'>■</b> Primary Blue: #28208C</span>
      <span class='swatch'><b style='color:#6B1C9B'>■</b> Royal Purple: #6B1C9B</span>
      <span class='swatch'><b style='color:#F59E0B'>■</b> Gold Accent: #F59E0B</span>
    </li>
  </ul>
</div>

<div class='footer'>Page 2 of 2 — Artist Dubai Production Graphics Specifications • Approved for Production</div>

</body>
</html>
"""

p1 = doc.new_page(width=595.3, height=841.9)
p1.insert_htmlbox(rect, html_p1)

p2 = doc.new_page(width=595.3, height=841.9)
p2.insert_htmlbox(rect, html_p2)

out_path = 'Artist_Dubai_Graphics_Specifications.pdf'
doc.save(out_path)
print(f'Successfully re-generated {out_path}')

# Copy to artifacts
dst = r'C:\Users\hp\.gemini\antigravity\brain\5597d95a-e819-497f-a734-8870e058ebbb\Artist_Dubai_Graphics_Specifications.pdf'
shutil.copyfile(out_path, dst)
print('Updated artifact copy.')
