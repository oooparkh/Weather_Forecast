import UIKit
import CoreLocation

class ViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak private var cityPickerView: UIPickerView!
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var getWeatherForecastButton: UIButton!
    @IBOutlet weak private var backgroundImageView: UIImageView!
    @IBOutlet weak private var blurEffectView: UIVisualEffectView!
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!

    // MARK: - Private properties

    private var countOfDays = 3
    private var apiURL: String = ""
    private var selectedCity: String = ""
    private var currentLocation = CLLocation()
    private var cities: [String] = [
        "Current location", "Vienna", "Brussels",
        "Minsk", "London", "Berlin", "Copenhagen",
        "Madrid", "Rome", "Riga", "Monaco",
        "Amsterdam", "Oslo", "Warsaw", "Moscow",
        "Kiev", "Helsinki", "Paris", "Prague",
        "Bern", "Stockholm", "Tallinn"
    ]
    private let startUrl = "https://api.weatherbit.io/v2.0/forecast/daily?city="

    private let apiKey = "&key=c3c71111c38b4cc49ac2e115c18a6dcc"
    private let viewModel = ViewModel()
    private let locationManager = CLLocationManager()

    // MARK: - Lifecycle functions

    override func viewDidLoad() {
        super.viewDidLoad()
        blurEffectView.alpha = 0.7
        navigationController?.navigationBar.isHidden = true

        cityPickerView.delegate = self
        cityPickerView.dataSource = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 15
        getWeatherForecastButton.layer.cornerRadius = 15

        activityIndicator.alpha = 1
        activityIndicator.startAnimating()

        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        currentLocation = locationManager.location ?? CLLocation()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.distanceFilter = 10
            locationManager.startUpdatingLocation()
        }
        getForecast()
    }

    // MARK: - IBActions

    @IBAction private func getWeatherForecastButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Select count of days", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "3 days", style: .default, handler: { (_) in
            self.countOfDays = 3
            self.getForecast()
        }))
        alert.addAction(UIAlertAction(title: "1 week", style: .default, handler: { (_) in
            self.countOfDays = 7
            self.getForecast()
        }))
        alert.addAction(UIAlertAction(title: "2 weeks", style: .default, handler: { (_) in
            self.countOfDays = 14
            self.getForecast()
        }))
        present(alert, animated: true)
    }

    // MARK: - Flow functions

   private func getForecast() {
        if cityPickerView.selectedRow(inComponent: 0) != 0 {
            selectedCity = cities[cityPickerView.selectedRow(inComponent: 0)]
            apiURL = startUrl + selectedCity + apiKey + "&days=\(countOfDays)"
        } else if cityPickerView.selectedRow(inComponent: 0) == 0 {
            let lat = currentLocation.coordinate.latitude
            let lon = currentLocation.coordinate.longitude
            apiURL = "https://api.weatherbit.io/v2.0/forecast/daily?lat=\(lat)&lon=\(lon)" +
                apiKey + "&days=\(countOfDays)"
        }
        sendRequest()
    }

   private func sendRequest() {
        viewModel.forecastDaily.bind { (forecast) in
            DispatchQueue.main.async {
                if forecast != nil {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.tableView.reloadData()
                } else {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.isHidden = false
                }
            }
        }
        viewModel.fetchForecast(url: apiURL)
    }
}

// MARK: - Extentions
// MARK: - Extension UIPickerView

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cities.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(cities[row])"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        getForecast()
    }

}

// MARK: - Extension UITableView

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = viewModel.forecastDaily.value?.data.count else {
            return 0
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nameCell = String(describing: ForecastTableViewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: nameCell,
                                                       for: indexPath) as? ForecastTableViewCell else {
            return UITableViewCell()
        }

        DispatchQueue.main.async {
            let forecasts = self.viewModel.forecastDaily.value
            cell.descriptionLabel.text = forecasts?.data[indexPath.row].weather.description
            if let imageName = forecasts?.data[indexPath.row].weather.icon {
                cell.weatherImageView.image = UIImage(named: imageName)
            }
            if let degrees = forecasts?.data[indexPath.row].temperature {
                cell.degreesLabel.text = "\(String(degrees))°C"
            }
            let dateFormetter = DateFormatter()
            dateFormetter.dateFormat = "yyyy-MM-dd"
            if let string = forecasts?.data[indexPath.row].date {
                if let date = dateFormetter.date(from: string) {
                    dateFormetter.dateFormat = "MMM d"
                    cell.dateLabel.text = dateFormetter.string(from: date)
                }
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nameController = String(describing: DailyForestViewController.self)
    let viewController = storyboard.instantiateViewController(identifier: nameController) as DailyForestViewController
        viewController.modalPresentationStyle = .fullScreen
        viewController.forecast = viewModel.forecastDaily.value
        viewController.index = indexPath.row
        viewController.totalDays = countOfDays
        navigationController?.pushViewController(viewController, animated: true)

    }
}

// MARK: - Extension CLLocationManager

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            tableView.reloadData()
        }
    }
}
