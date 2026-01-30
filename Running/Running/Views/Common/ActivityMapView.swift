//
//  ActivityMapView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI
import MapKit

struct ActivityMapView: UIViewRepresentable {
    let routes: [ActivityRoute]
    let isInteractive: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = isInteractive
        mapView.showsUserLocation = true // 현재 위치 표시
        
        // Configure map style
        mapView.mapType = .standard
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        if routes.isEmpty {
            // 현재 위치로 지도 이동 (사용자 위치가 있으면)
            if let userLocation = mapView.userLocation.location {
                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005) // 더 확대
                )
                mapView.setRegion(region, animated: false)
            } else {
                // 위치가 없으면 서울로 기본값
                let region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005) // 더 확대
                )
                mapView.setRegion(region, animated: false)
            }
            return
        }
        
        // Create annotations for start and end points
        if let firstRoute = routes.first {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = CLLocationCoordinate2D(latitude: firstRoute.lat, longitude: firstRoute.long)
            startAnnotation.title = "시작"
            mapView.addAnnotation(startAnnotation)
        }
        
        if let lastRoute = routes.last, routes.count > 1 {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = CLLocationCoordinate2D(latitude: lastRoute.lat, longitude: lastRoute.long)
            endAnnotation.title = "종료"
            mapView.addAnnotation(endAnnotation)
        }
        
        // Create polyline for route
        if routes.count > 1 {
            let coordinates = routes.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.long) }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            
            // Fit map to show all routes
            let rect = polyline.boundingMapRect
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        } else if let route = routes.first {
            // Single point - center on it
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: route.lat, longitude: route.long),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color.emerald500)
                renderer.lineWidth = 4.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pointAnnotation = annotation as? MKPointAnnotation else {
                return nil
            }
            
            let identifier = "RouteAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize based on title
            if let markerView = annotationView as? MKMarkerAnnotationView {
                if pointAnnotation.title == "시작" {
                    markerView.markerTintColor = UIColor(Color.emerald500)
                } else if pointAnnotation.title == "종료" {
                    markerView.markerTintColor = UIColor(Color.orange500)
                }
            }
            
            return annotationView
        }
    }
}


#Preview {
    ActivityMapView(
        routes: [
            ActivityRoute(
                id: 1,
                uuid: UUID().uuidString,
                createdAt: Date(),
                deletedAt: nil,
                activityId: 1,
                lat: 37.5665,
                long: 126.9780,
                speed: nil,
                altitude: nil,
                seq: 1
            ),
            ActivityRoute(
                id: 2,
                uuid: UUID().uuidString,
                createdAt: Date(),
                deletedAt: nil,
                activityId: 1,
                lat: 37.5670,
                long: 126.9785,
                speed: nil,
                altitude: nil,
                seq: 2
            )
        ],
        isInteractive: true
    )
    .frame(height: 300)
}

