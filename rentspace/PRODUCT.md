# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

1. **Renters / Customers (`customer` / `renter`)**: University students, remote workers, creators, and small teams looking to discover, compare, and request hourly or daily bookings for temporary spaces (study rooms, meeting rooms, music rooms, studios, and event spaces) without fragmented social-media inquiries.
2. **Space Owners (`owner`)**: Property and venue hosts who want to monetize underutilized rooms by publishing listings, setting pricing/capacity, and confirming or rejecting incoming booking requests.
3. **Platform Administrators (`admin`)**: Moderators responsible for reviewing and approving pending listings before public visibility, managing user account statuses (`active` / `suspended`), inspecting reservations, and maintaining an append-only audit trail.

## Product Purpose

RentSpace connects people who need temporary spaces with venue owners who have spaces available for rent. Success means renters can filter verified listings with transparent pricing and capacity, submit conflict-free reservation requests, and track booking status, while owners and administrators have clear, low-friction workflows for listing management and platform moderation.

## Positioning

A unified, moderated space-rental marketplace with three-role governance (`Renter`, `Owner`, `Admin`), mandatory listing approval before public search visibility, and overlap-checked booking confirmation backed by a relational MySQL database (`rent_space`).

## Operating Context

- **Frontend Workspace**: Flutter cross-platform application (`c:\proMOBILE\rentspace_frontend`) following an MVC architecture (`lib/models`, `lib/controllers`, `lib/screens`).
- **Backend Server Workspace**: Standalone Node.js + Express REST API server (`c:\proMOBILE\server`) connecting to XAMPP MySQL (`e:\xampp\mysql\bin\mysql.exe`) via `mysql2/promise` connection pooling.
- **Database (`rent_space`)**: Relational schema (`users`, `spaces`, `bookings`) seeded with Thai/English sample records (`ห้องประชุมสว่างใจ`, `สตูดิโอแสงธรรมชาติ`, `พื้นที่จัดเวิร์กช็อป`, `demo_owner`, `demo_customer`, `demo_admin`).

## Capabilities and Constraints

- **Role-Based Access**: Three distinct roles (`renter`/`customer`, `owner`, `admin`); public registration is strictly limited to `renter` and `owner` accounts (admin accounts are provisioned only by administrators).
- **Moderation Gate**: Newly created or edited space listings default to `pending` status; only `approved` and active listings appear in public renter search results.
- **Reservation Integrity**: Bookings require `end_time > start_time` (or `end_date > start_date`), prevent overlapping `confirmed`/`approved` reservations for the same space, and compute total pricing deterministically.
- **Bilingual Thai/English UI Copy**: Primary interface labels, status feedback, and seed data use clear Thai copy paired with standard English domain terms (`Renter`, `Owner`, `Admin`, `Pending`, `Confirmed`).

## Brand Commitments

- **Product Name**: RentSpace — Space Rental and Booking Application (`แอปรวมพื้นที่ให้เช่ารายชั่วโมง/รายวัน`).

## Evidence on Hand

- Project specification: `c:\Users\AutoOS\Downloads\RentSpace_Project_Documentation.md`
- Database schema & seed SQL: `c:\proMOBILE\server\database\rent_space.sql` and `c:\proMOBILE\server\database\seed.sql`
- Automated widget & unit test suite: `c:\proMOBILE\rentspace_frontend\test\widget_test.dart`
- No external customer testimonials, live payment gateway, or production SLA claims exist in the MVP; future UI work must not fabricate them.

## Product Principles

1. **Trust Before Visibility**: Every space listing passes through explicit administrator approval before appearing in public search, and every moderation action is traceable.
2. **Transparent Pricing & Availability**: Surface hourly/daily rates, capacity, location, and occupied time slots upfront so renters never have to guess before requesting a booking.
3. **Role-Scoped Clarity**: Keep Renter discovery, Owner inventory/request management, and Admin moderation clearly separated with zero cross-role clutter.
4. **Resilient Offline/Online Operation**: Synchronize seamlessly with the XAMPP MySQL backend (`http://localhost:3000`) while maintaining responsive state and deterministic validation in the Flutter client.
