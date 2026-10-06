# NFMS-FIP GitHub Pages Prototype

This is a complete static frontend prototype for the National Forest Monitoring System (NFMS-FIP) interface shown in the supplied reference image.

## Included
- Kenya Government crest and Kenya Forest Service logo cropped from the supplied reference image.
- Matching forest hero image, green navigation, sidebar, ticker, breadcrumbs and content-card styling.
- Landing page focused on: What is NFMS, four main functional areas, Featured Forest Information, Partners & Collaboration, News & Events and Footer/Contact.
- Functional navigation using hash routing so it works directly from GitHub Pages without a build system.
- Search, responsive mobile navigation and a demo login modal.
- Data submission workflow: **Upload → Validate → Review → Approve → Publish → Display on NFMS**.
- Role model for Public User, Data Provider, Technical Reviewer / NTC and KFS NFMS Super User.

## Deploy on GitHub Pages

1. Create a repository, for example `nfms-fip`.
2. Upload all files and the `assets` folder to the repository root.
3. Go to **Settings → Pages**.
4. Under **Build and deployment**, select **Deploy from a branch**.
5. Select branch **main** and folder **/ (root)**, then save.
6. Open the published GitHub Pages URL.

## Production note

This repository is the frontend only. The login control, dataset upload, technical review, approval and publication actions are represented in the interface but need to be connected to your existing NFMS-FIP/Django/GeoNode backend, authentication provider and API before they can persist real users or datasets.
