import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { CourseProvider } from './context/CourseContext';
import { TaskProvider } from './context/TaskContext';
import Navbar from './components/layout/Navbar';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import BoardPage from './pages/tasks/BoardPage';
import CoursePage from './pages/courses/CoursePage';
import ProfilePage from './pages/profile/ProfilePage';
import { ThemeProvider } from './context/ThemeContext';

function PrivateRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) return <div className="page-shell">Memuat...</div>;
  return user ? children : <Navigate to="/login" replace />;
}

function MainLayout({ children }) {
  return (
    <>
      <Navbar />
      <main className="app-main">
        {children}
      </main>
    </>
  );
}

function AnimatedRoutes() {
  const location = useLocation();

  return (
    <div key={location.pathname} className="route-anim">
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />

        <Route
          path="/"
          element={
            <PrivateRoute>
              <MainLayout>
                <BoardPage />
              </MainLayout>
            </PrivateRoute>
          }
        />
        <Route
          path="/courses"
          element={
            <PrivateRoute>
              <MainLayout>
                <CoursePage />
              </MainLayout>
            </PrivateRoute>
          }
        />
        <Route
          path="/profile"
          element={
            <PrivateRoute>
              <MainLayout>
                <ProfilePage />
              </MainLayout>
            </PrivateRoute>
          }
        />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </div>
  );
}

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <TaskProvider>
          <CourseProvider>
            <BrowserRouter>
              <AnimatedRoutes />
            </BrowserRouter>
          </CourseProvider>
        </TaskProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
