import Foundation

class ViewModel {
    private let api = APIManager()

    let forecastDaily: Observable<ForecastDaily?> = Observable(nil)

    func fetchForecast(url: String) {
        api.fetchForecast(url: url) { (result) in
            switch result {
            case .success(let forecast):
                self.forecastDaily.value = forecast
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
