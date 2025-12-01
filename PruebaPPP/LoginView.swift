import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // Animaciones
    @State private var animateGradient = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Fondo Premium con Gradiente Animado
            LinearGradient(colors: [Color.black, Color(hex: "0F1C10"), Color(hex: "002200")], startPoint: animateGradient ? .topLeading : .bottomLeading, endPoint: animateGradient ? .bottomTrailing : .topTrailing)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
            
            // Efecto de ruido sutil (opcional)
            Color.white.opacity(0.02)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo y Título
                VStack(spacing: 15) {
                    Image("Logo") // Usando el asset 'Logo'
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        // Sin efectos de sombra/neon
                    
                    Text("GymRatp")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(isSignUp ? "Crea tu cuenta" : "Bienvenido de nuevo")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .offset(y: showContent ? 0 : -20)
                .opacity(showContent ? 1 : 0)
                
                VStack(spacing: 20) {
                    // Email Field
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(.white)
                            .accentColor(.neonGreen)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Password Field
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        
                        SecureField("Contraseña", text: $password)
                            .foregroundColor(.white)
                            .accentColor(.neonGreen)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 30)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                
                // Botón de Acción Principal
                Button(action: handleAction) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text(isSignUp ? "Crear Cuenta" : "Iniciar Sesión")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.neonGreen, .green], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: .neonGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .disabled(isLoading)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                
                // Switch Login/Signup
                Button(action: {
                    withAnimation(.spring()) {
                        isSignUp.toggle()
                        errorMessage = ""
                    }
                }) {
                    HStack {
                        Text(isSignUp ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?")
                            .foregroundColor(.gray)
                        Text(isSignUp ? "Inicia Sesión" : "Regístrate")
                            .fontWeight(.bold)
                            .foregroundColor(.neonGreen)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    func handleAction() {
        guard !email.isEmpty, !password.isEmpty else {
            withAnimation {
                errorMessage = "Por favor llena todos los campos"
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        if isSignUp {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                isLoading = false
                if let error = error {
                    withAnimation {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                isLoading = false
                if let error = error {
                    withAnimation {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}


