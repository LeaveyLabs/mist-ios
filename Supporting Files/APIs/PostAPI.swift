// Acquires posts from the datbase
static func fetchPosts() async throws -> [Post] {
    guard let url = URL(string: "https://mist-backend.herokuapp.com/api/posts/") else {
        return [];
    }
    let (data, _) = try await URLSession.shared.data(from: url);
    let result = try JSONDecoder().decode([Post].self, from: data);
    return result
}

// Creates post in the database
static func createPost(post:Post) async throws -> Bool {
    guard let serviceUrl = URL(string: "https://mist-backend.herokuapp.com/api/posts/") else {
        return false;
    }
    var request = URLRequest(url: serviceUrl);
    let jsonEncoder = JSONEncoder()
    let jsonData = try jsonEncoder.encode(post)
    request.httpMethod = "POST";
    request.httpBody = jsonData;
    request.setValue("application/json", forHTTPHeaderField: "Content-Type");
    let (data, _) = try await URLSession.shared.data(for: request);
    return true;
}