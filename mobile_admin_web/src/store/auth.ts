import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  access: string | null;
  refresh: string | null;
  userId: number | null;
  setTokens: (access: string, refresh: string, userId: number) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      access: null,
      refresh: null,
      userId: null,
      setTokens: (access, refresh, userId) => set({ access, refresh, userId }),
      logout: () => set({ access: null, refresh: null, userId: null }),
    }),
    { name: 'altatheeb-admin-auth' },
  ),
);
