# Admin Panel Architecture & Workflow Blueprint - SLOT Platform

> **Primary Blueprint**: `/Users/manishdubey/Downloads/SBS/SLOT Admin Panel Workflow Blueprint.png`  
> **Target Framework**: Flutter Web (Desktop-first responsive implementation)

---

## 1. Responsive Navigation System

- **Desktop (> 1024px)**: Fixed left sidebar (`width: 240px`, dark neutral `#1C1917`) with header logo and platform module links.
- **Tablet (600px - 1024px)**: Collapsible compact icon sidebar.
- **Mobile (< 600px)**: Top `AppBar` with slide-out navigation `Drawer`.

---

## 2. Core Admin Modules

1. **Dashboard**: Platform overview metrics (Total Salons, Active Salons, Pending Approvals, Total Users, Total Bookings, GMV & Revenue charts).
2. **Salons & Onboarding**: Complete approval workflow table for salon applications.
3. **User Management**: Role management and block/activate security actions.
4. **Booking Management**: Multi-salon live booking inspection and dispute resolution.
5. **Audit Logs**: Full system activity log tracking all sensitive administrative actions.
