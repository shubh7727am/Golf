![App icon](images/autobot.png)

# Golf App with IoT Integration

The Golf App is an innovative tool designed for golfers to analyze their shots in real-time. By integrating IoT devices, the app measures the speed and deflection of golf balls, providing actionable insights to improve your game.

## App Screenshots

<p align="center">
  <img src="App_ss/1.png" width="30%" />
  <img src="App_ss/2.png" width="30%" />
  <img src="App_ss/3.png" width="30%" />
</p>

## Features

- **Real-Time Data Analysis**:
  - Measure **Speed** and **Deflection** of the golf ball using IoT sensors.
- **Data Persistence**:
  - **Online**: Sync data to **AWS DynamoDB** for cloud storage and analysis.
  - **Offline**: Use **SharedPreferences** to save data locally.
- **MQTT Protocol**:
  - Communicate with IoT devices for seamless data transfer.
- **Progress Tracking**:
  - View historical data and performance trends.
- **Customizable Alerts**:
  - Set thresholds for speed and deflection to receive instant feedback.
- **User-Friendly Interface**:
  - Clean design with Light and Dark themes.


## Technology Stack

- **Flutter**: Cross-platform UI framework.
- **MVVM Architecture**: Ensures a clean separation of concerns and testability.
- **MQTT Protocol**: Facilitates communication between the app and IoT devices.
- **AWS DynamoDB**: Cloud database for storing golf data.
- **SharedPreferences**: Offline storage for user data.
- **Custom Charts**: Dynamic visualizations for speed and deflection trends.

## Setup & Compilation Instructions

### Prerequisites:
- Dart version: 3.5.4
- DevTools version: 2.37.3
- Flutter version: 3.24.5 (Stable)


## Design Decisions

- **Scalability Focus**: The MVVM architecture ensures the app is extensible and maintainable.
- **Real-Time Processing**: Data from IoT devices is processed and displayed instantly using MQTT.
- **Custom Charts**: Engaging visualizations enhance user experience and provide clear insights.
- **Error Handling**: Robust mechanisms for connectivity issues and data inconsistencies.

---
Developed by Shubham choudhary
