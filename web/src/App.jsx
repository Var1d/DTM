import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { CourseProvider } from './context/CourseContext';
import { TaskProvider } from './context/TaskContext';
import Navbar from './components/layout/Navbar';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import BoardPage from './pages/tasks/BoardPage';
import CoursePage from './pages/courses/CoursePage';
import ProfilePage from './pages/profile/ProfilePage';

function PrivateRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) return <div style={{ textAlign: 'center', padding: 80 }}>Memuat...</div>;
  return user ? children : <Navigate to="/login" replace />;
}

function MainLayout({ children }) {
  return (
    <>
      <Navbar />
      <main style={{ minHeight: 'calc(100vh - 56px)', background: '#f5f5f5' }}>
        {children}
      </main>
    </>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <TaskProvider>
        <CourseProvider>
          <BrowserRouter>
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
          </BrowserRouter>
        </CourseProvider>
      </TaskProvider>
    </AuthProvider>
  );
}
