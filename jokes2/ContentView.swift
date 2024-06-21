//
//  ContentView.swift
//  jokes2
//
//  Created by Rahul Verma on 12/06/23.
//
import SwiftUI

enum JokeError: Error {
    case urlNotCorrect
    case invalidResponse
    case jsonNotParsable
    case unexpectedError
}

struct jokeInstance: Codable {
    let id: String
    let joke: String
    let status: Int
}

struct ContentView: View {
    @State var joke: jokeInstance?
    @State var isCopied: Bool = false
    var url: String = "https://icanhazdadjoke.com/"
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.blue, .white]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.black)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.black, .gray]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 350, height: 300)
                    .shadow(radius: 10)
                    .overlay(
                        Text(joke?.joke ?? "No jokes yet")
                            .fontWeight(.bold)
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    )
                    .animation(.easeInOut)
                    .gesture(
                        DragGesture()
                            .onChanged { _ in }
                            .onEnded { value in
                                if value.translation.width < 0 {
                                    fetchNewJoke()
                                }
                            }
                    )
                
                Button(action: {
                    copyJoke()
                }) {
                    Text(isCopied ? "Copied!" : "Copy")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.top, 10)
                }
            }
        }
        .onAppear {
            fetchNewJoke()
        }
    }
    
    func fetchNewJoke() {
        getJoke(urlString: url) { result in
            switch result {
            case .success(let joke):
                self.joke = joke  // Handle the retrieved joke
            case .failure(let error):
                print(error)  // Handle the error
            }
        }
    }
    
    func getJoke(urlString: String, completion: @escaping (Result<jokeInstance, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "Invalid URL", code: 0, userInfo: nil)
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    let res = try JSONDecoder().decode(jokeInstance.self, from: data)
                    completion(.success(res))
                } catch {
                    completion(.failure(error))
                }
            } else {
                let error = NSError(domain: "No data received", code: 0, userInfo: nil)
                completion(.failure(error))
            }
        }.resume()
    }
    
    func copyJoke() {
        guard let jokeText = joke?.joke else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [jokeText], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



