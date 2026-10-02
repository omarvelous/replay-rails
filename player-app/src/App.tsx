import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { AuthProvider } from "./context/AuthContext"
import { PlayerShell } from "./components/PlayerShell"

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 2,
    },
  },
})

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <PlayerShell />
      </AuthProvider>
    </QueryClientProvider>
  )
}
