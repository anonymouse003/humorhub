import SwiftUI

enum JokeError: Error, LocalizedError {
    case urlNotCorrect
    case invalidResponse
    case jsonNotParsable
    case unexpectedError
    
    var errorDescription: String? {
        switch self {
        case .urlNotCorrect:
            return "The URL provided is incorrect."
        case .invalidResponse:
            return "The response from the server was invalid."
        case .jsonNotParsable:
            return "The JSON data could not be parsed."
        case .unexpectedError:
            return "An unexpected error occurred."
        }
    }
}

struct JokeInstance: Codable, Identifiable {
    let id: String
    let joke: String
    let status: Int
}

struct ContentView: View {
    @State private var joke: JokeInstance?
    @State private var isCopied = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var themeIndex = 0
    private let url = "https://icanhazdadjoke.com/"
    
    private let themes: [Gradient] = [
        Gradient(colors: [.purple, .blue]),
        Gradient(colors: [.orange, .pink]),
        Gradient(colors: [.green, .yellow]),
        Gradient(colors: [.red, .purple])
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: themes[themeIndex], startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HeaderView(changeTheme: changeTheme)
                
                if isLoading {
                    ProgressView("Fetching a joke...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                } else if let joke = joke {
                    JokeView(joke: joke.joke)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                fetchNewJoke()
                            }
                        }
                } else {
                    PlaceholderView(message: errorMessage ?? "Tap to fetch a joke!")
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                fetchNewJoke()
                            }
                        }
                }
                
                Spacer()
                
                Button(action: {
                    copyJoke()
                }) {
                    Text(isCopied ? "Copied!" : "Copy")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(.bottom, 20)
                }
                .scaleEffect(isCopied ? 1.2 : 1)
                .animation(.easeInOut(duration: 0.3), value: isCopied)
                
                if let _ = errorMessage {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            fetchNewJoke()
                        }
                    }) {
                        Text("Retry")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                            .padding(.bottom, 20)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            fetchNewJoke()
        }
    }
    
    private func fetchNewJoke() {
        isLoading = true
        errorMessage = nil
        
        getJoke(urlString: url) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let joke):
                    self.joke = joke
                case .failure(let error):
                    self.joke = nil
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func getJoke(urlString: String, completion: @escaping (Result<JokeInstance, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(JokeError.urlNotCorrect))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(JokeError.invalidResponse))
                return
            }
            
            do {
                let joke = try JSONDecoder().decode(JokeInstance.self, from: data)
                completion(.success(joke))
            } catch {
                completion(.failure(JokeError.jsonNotParsable))
            }
        }.resume()
    }
    
    private func copyJoke() {
        guard let jokeText = joke?.joke else {
            return
        }
        
        UIPasteboard.general.string = jokeText
        isCopied = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }
    
    private func changeTheme() {
        themeIndex = (themeIndex + 1) % themes.count
    }
}

struct HeaderView: View {
    var changeTheme: () -> Void
    
    var body: some View {
        HStack {
            Text("Random Dad Joke")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .padding(.top, 20)
            Spacer()
            Button(action: {
                withAnimation(.easeInOut) {
                    changeTheme()
                }
            }) {
                Image(systemName: "paintpalette")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
    }
}

struct JokeView: View {
    let joke: String
    
    var body: some View {
        Text(joke)
            .fontWeight(.semibold)
            .font(.system(size: 22))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.black)
                    .opacity(0.8)
                    .shadow(radius: 10)
            )
            .padding(.horizontal, 20)
            .transition(.opacity)
    }
}

struct PlaceholderView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .fontWeight(.semibold)
            .font(.system(size: 22))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.gray)
                    .opacity(0.8)
                    .shadow(radius: 10)
            )
            .padding(.horizontal, 20)
            .transition(.opacity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

