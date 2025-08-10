from typing import List, Tuple

def decode_polyline(encoded: str, precision: int = 5) -> List[Tuple[float, float]]:
    """
    Decode a polyline encoded with Google's algorithm.
    
    Args:
        encoded: The encoded polyline string.
        precision: Number of decimal places used during encoding (default 5).
        
    Returns:
        List of (lat, lon) tuples.
    """
    coordinates: List[Tuple[float, float]] = []
    index = 0
    lat = 0
    lng = 0
    factor = 10 ** precision

    try:
        while index < len(encoded):
            # Decode latitude
            result = 0
            shift = 0
            while True:
                b = ord(encoded[index]) - 63
                index += 1
                result |= (b & 0x1F) << shift
                shift += 5
                if b < 0x20:
                    break
            dlat = ~(result >> 1) if (result & 1) else (result >> 1)
            lat += dlat

            # Decode longitude
            result = 0
            shift = 0
            while True:
                b = ord(encoded[index]) - 63
                index += 1
                result |= (b & 0x1F) << shift
                shift += 5
                if b < 0x20:
                    break
            dlng = ~(result >> 1) if (result & 1) else (result >> 1)
            lng += dlng

            coordinates.append((lat / factor, lng / factor))
    except IndexError:
        raise ValueError("Truncated or invalid encoded polyline.")

    return coordinates
