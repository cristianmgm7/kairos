# Kairos Landing Page

A modern, responsive static website for the Kairos AI journaling app. Built with pure HTML, CSS, and JavaScript for optimal performance and easy deployment to Netlify.

## Features

- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Modern UI**: Material 3-inspired design with smooth animations
- **SEO Optimized**: Proper meta tags and semantic HTML
- **Fast Loading**: No build process, minimal dependencies
- **Accessibility**: WCAG compliant with proper ARIA labels
- **Privacy Policy**: Comprehensive privacy and terms pages

## Project Structure

```
landing_page/
├── index.html          # Main landing page
├── privacy.html        # Privacy Policy & Terms of Service
├── css/
│   └── style.css      # All styles (includes responsive design)
├── js/
│   └── main.js        # Smooth scrolling & animations
├── images/            # App screenshots, logos, etc.
├── netlify.toml       # Netlify deployment configuration
└── README.md          # This file
```

## Local Development

### Prerequisites

- A modern web browser (Chrome, Firefox, Safari, Edge)
- Optional: A local web server for testing

### Running Locally

**Option 1: Open directly in browser**
```bash
# Navigate to the landing_page directory
cd landing_page

# Open index.html in your browser
open index.html  # macOS
start index.html # Windows
xdg-open index.html # Linux
```

**Option 2: Use Python's built-in server (recommended)**
```bash
# Python 3
python3 -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000

# Then open http://localhost:8000 in your browser
```

**Option 3: Use Node.js http-server**
```bash
# Install globally
npm install -g http-server

# Run in landing_page directory
http-server -p 8000

# Open http://localhost:8000
```

## Deploying to Netlify

### Method 1: Drag and Drop (Easiest)

1. Go to [Netlify](https://app.netlify.com)
2. Sign up or log in
3. Drag the `landing_page` folder onto the Netlify dashboard
4. Your site is live! Netlify will provide a URL like `https://random-name.netlify.app`

### Method 2: Git Integration (Recommended for updates)

1. **Create a Git repository** (if not already done):
   ```bash
   cd landing_page
   git init
   git add .
   git commit -m "Initial landing page"
   ```

2. **Push to GitHub/GitLab/Bitbucket**:
   ```bash
   # Create a repo on GitHub, then:
   git remote add origin https://github.com/yourusername/kairos-landing.git
   git branch -M main
   git push -u origin main
   ```

3. **Connect to Netlify**:
   - Go to [Netlify](https://app.netlify.com)
   - Click "New site from Git"
   - Connect your Git provider
   - Select your repository
   - Configure build settings:
     - **Base directory**: `landing_page`
     - **Build command**: (leave empty)
     - **Publish directory**: `landing_page`
   - Click "Deploy site"

4. **Automatic deployments**:
   - Any push to your main branch will trigger a new deployment
   - Netlify will automatically rebuild and publish your site

### Method 3: Netlify CLI

1. **Install Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   ```

2. **Login to Netlify**:
   ```bash
   netlify login
   ```

3. **Initialize site**:
   ```bash
   cd landing_page
   netlify init
   ```

4. **Deploy**:
   ```bash
   # Deploy to draft URL
   netlify deploy

   # Deploy to production
   netlify deploy --prod
   ```

## Custom Domain Setup

1. **Purchase a domain** (e.g., from Namecheap, Google Domains, etc.)

2. **Add domain to Netlify**:
   - Go to Site settings → Domain management
   - Click "Add custom domain"
   - Enter your domain (e.g., `kairos-app.com`)

3. **Update DNS records**:

   **Option A: Use Netlify DNS (recommended)**:
   - Netlify will provide nameservers
   - Update your domain registrar to use Netlify's nameservers
   - Netlify handles everything else

   **Option B: Use external DNS**:
   - Add these DNS records at your domain registrar:
     ```
     Type: A
     Name: @
     Value: 75.2.60.5

     Type: CNAME
     Name: www
     Value: your-site.netlify.app
     ```

4. **Enable HTTPS**:
   - Netlify automatically provides free SSL via Let's Encrypt
   - HTTPS will be enabled within minutes of DNS propagation

## Customization Guide

### Updating Content

1. **Change app name/branding**:
   - Update text in `index.html` and `privacy.html`
   - Update `<title>` and meta tags

2. **Add app screenshots**:
   - Place images in `images/` directory
   - Update the `.phone-mockup` section in `index.html`:
     ```html
     <div class="phone-mockup">
       <img src="images/app-screenshot.png" alt="Kairos App">
     </div>
     ```

3. **Update store links**:
   - Replace `#` in the download buttons with actual App Store/Google Play URLs:
     ```html
     <a href="https://apps.apple.com/app/your-app-id" class="store-button">
     <a href="https://play.google.com/store/apps/details?id=com.kairos" class="store-button">
     ```

4. **Change colors**:
   - Edit CSS variables in `css/style.css`:
     ```css
     :root {
       --primary-color: #6750A4;  /* Your brand color */
       --secondary-color: #03DAC6;
     }
     ```

5. **Update privacy policy**:
   - Edit `privacy.html` with your specific details:
     - Data storage locations
     - Contact emails
     - Legal jurisdiction
     - Company name

### Adding Features

**Contact Form (using Netlify Forms)**:
```html
<form name="contact" method="POST" data-netlify="true">
  <input type="email" name="email" placeholder="Your email" required>
  <textarea name="message" placeholder="Your message" required></textarea>
  <button type="submit">Send</button>
</form>
```

**Google Analytics**:
```html
<!-- Add before </head> in index.html -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

## Optimization Tips

### Performance

1. **Compress images**:
   ```bash
   # Use ImageOptim, TinyPNG, or CLI tools
   npm install -g imagemin-cli
   imagemin images/* --out-dir=images/optimized
   ```

2. **Minify CSS/JS** (optional for production):
   ```bash
   npm install -g clean-css-cli uglify-js
   cleancss -o css/style.min.css css/style.css
   uglifyjs js/main.js -o js/main.min.js
   ```

### SEO

1. **Update meta tags** in `index.html`:
   - Description: Keep under 160 characters
   - Keywords: Focus on relevant terms
   - Open Graph tags for social sharing

2. **Create sitemap.xml**:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
     <url>
       <loc>https://kairos-app.com/</loc>
       <changefreq>weekly</changefreq>
       <priority>1.0</priority>
     </url>
     <url>
       <loc>https://kairos-app.com/privacy.html</loc>
       <changefreq>monthly</changefreq>
       <priority>0.5</priority>
     </url>
   </urlset>
   ```

3. **Add robots.txt**:
   ```
   User-agent: *
   Allow: /
   Sitemap: https://kairos-app.com/sitemap.xml
   ```

## Environment Variables (if needed)

Create a `.env` file for API keys or configuration:
```bash
# Not tracked in git
GOOGLE_ANALYTICS_ID=GA_MEASUREMENT_ID
CONTACT_FORM_ENDPOINT=https://your-backend.com/contact
```

Access in Netlify:
- Site settings → Build & deploy → Environment variables

## Troubleshooting

### Site not loading after deployment
- Check Netlify build logs for errors
- Verify `netlify.toml` publish directory is correct
- Ensure all file paths use relative paths (not absolute)

### Styles not applying
- Clear browser cache
- Check that `style.css` path is correct in HTML
- Verify CSS file is in the `css/` directory

### Images not showing
- Ensure images are in the `images/` directory
- Use relative paths: `images/logo.png` (not `/images/logo.png`)
- Check image file names match exactly (case-sensitive)

### Custom domain not working
- Wait for DNS propagation (can take 24-48 hours)
- Use [DNS Checker](https://dnschecker.org) to verify records
- Ensure CNAME/A records are correctly configured

## Maintenance

### Regular Updates

1. **Content updates**: Edit HTML files directly
2. **Security**: Keep dependencies minimal (currently none!)
3. **Testing**: Test on multiple browsers and devices
4. **Monitoring**: Use Netlify Analytics or Google Analytics

### Backup

Always commit changes to Git:
```bash
git add .
git commit -m "Update landing page content"
git push origin main
```

## Resources

- [Netlify Documentation](https://docs.netlify.com/)
- [Material Design 3](https://m3.material.io/)
- [MDN Web Docs](https://developer.mozilla.org/)
- [Can I Use](https://caniuse.com/) - Browser compatibility

## Support

For issues related to:
- **Landing page code**: Create an issue in your repository
- **Netlify deployment**: Check [Netlify Support](https://www.netlify.com/support/)
- **Kairos app**: Contact support@kairos-app.com

## License

© 2025 Kairos. All rights reserved.

---

**Need help?** Contact: support@kairos-app.com
