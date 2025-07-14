import { LightningElement, api, track } from "lwc";

export default class FlightDetails extends LightningElement {
  @track flightData = [];

  @api
  get value() {
    return this._value;
  }
  /**
   * @param  {} value
   */
  set value(value) {
    this._value = value;
  }

  // Method to convert duration from minutes to hours and minutes
  formattedDuration(durationInMin) {
    if (durationInMin) {
      const hours = Math.floor(durationInMin / 60); // Get whole hours
      const minutes = durationInMin % 60; // Get remaining minutes
      return `${hours} hr ${minutes} min`;
    }
    return;
  }

  // Method to calculate arrival time based on departure time and duration
  arrivalTime(departureTime, durationInMin) {
    const [hours, minutes] = departureTime.split(":").map((num) => parseInt(num));
    const departureDate = new Date(2025, 0, 1, hours, minutes); // Sample date for calculation

    const arrivalDate = new Date(departureDate.getTime() + durationInMin * 60000); // Add duration to departure time

    const arrivalHours = String(arrivalDate.getHours()).padStart(2, "0");
    const arrivalMinutes = String(arrivalDate.getMinutes()).padStart(2, "0");

    return `${arrivalHours}:${arrivalMinutes}`;
  }

  connectedCallback() {
    if (this.value) {
      this.updatedValue = [];
      this.value.flights.map((flight) => {
        this.updatedValue.push({
          ...flight,
          arrivalInHr: this.arrivalTime(flight.departureTime, flight.durationInMin),
          petAllowedStatus: this.value.isPetAllowed ? "Yes" : "No",
          durationInHr: this.formattedDuration(flight.durationInMin),
        });
      });
      // this.value.updatedFlights = this.updatedValue;
      this.flightData = this.updatedValue;
    }
  }
}