import { Navigate, Route, Routes } from 'react-router-dom';
import { Shell } from './components/Shell';
import { LoginPage } from './pages/Login';
import { UsersPage } from './pages/Users';
import { FeatureFlagsPage } from './pages/FeatureFlags';
import { MinAppVersionPage } from './pages/MinAppVersion';
import { WebhookDeliveriesPage } from './pages/WebhookDeliveries';
import { AuditPage } from './pages/Audit';
import { useAuthStore } from './store/auth';

function RequireAuth({ children }: { children: JSX.Element }) {
  const access = useAuthStore((s) => s.access);
  if (!access) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <RequireAuth>
            <Shell />
          </RequireAuth>
        }
      >
        <Route index element={<Navigate to="/users" replace />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="feature-flags" element={<FeatureFlagsPage />} />
        <Route path="min-app-version" element={<MinAppVersionPage />} />
        <Route path="webhook-deliveries" element={<WebhookDeliveriesPage />} />
        <Route path="audit" element={<AuditPage />} />
      </Route>
    </Routes>
  );
}
