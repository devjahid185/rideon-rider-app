const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.getNearbyDrivers = functions.https.onCall(async (data, context) => {
  const { lat, lng, radiusKm } = data;

  if (typeof lat !== "number" || typeof lng !== "number" || typeof radiusKm !== "number") {
    throw new functions.https.HttpsError("invalid-argument", "lat, lng, and radiusKm must be numbers");
  }

  try {
    const driversRef = admin.firestore()
      .collection("drivers")
      .where("is_available", "==", true)
      .where("approvedStatus", "==", "pending")
      .where("driverStatus", "==", "inactive");

    const snapshot = await driversRef.get();

    const toRadians = (deg) => (deg * Math.PI) / 180;
    const EARTH_RADIUS_KM = 6371;

    const calculateDistance = (lat1, lng1, lat2, lng2) => {
      const dLat = toRadians(lat2 - lat1);
      const dLng = toRadians(lng2 - lng1);
      const a = Math.sin(dLat / 2) ** 2 +
                Math.cos(toRadians(lat1)) *
                Math.cos(toRadians(lat2)) *
                Math.sin(dLng / 2) ** 2;
      return EARTH_RADIUS_KM * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
    };

    const nearbyDrivers = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      const geo = data.location?.geopoint;

      if (geo?.latitude && geo?.longitude) {
        const distance = calculateDistance(lat, lng, geo.latitude, geo.longitude);
        if (distance <= radiusKm) {
          nearbyDrivers.push({ id: doc.id, ...data, distance });
        }
      }
    });

    nearbyDrivers.sort((a, b) => a.distance - b.distance);

    return nearbyDrivers;
  } catch (error) {
    console.error("Error fetching nearby drivers:", error);
    throw new functions.https.HttpsError("internal", "Unable to fetch nearby drivers.");
  }
});
