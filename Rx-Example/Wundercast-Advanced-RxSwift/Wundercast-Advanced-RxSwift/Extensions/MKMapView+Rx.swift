//
//  MKMapView+Rx.swift
//  Wundercast-Advanced-RxSwift
//
//  Created by SHIN YOON AH on 2021/11/25.
//

import Foundation
import MapKit
import RxSwift
import RxCocoa

extension MKMapView: HasDelegate {
    public typealias Delegate = MKMapViewDelegate
}

class RxMKMapViewDelegateProxy: DelegateProxy<MKMapView, MKMapViewDelegate>, DelegateProxyType, MKMapViewDelegate {
    
    public weak private(set) var mapView: MKMapView?
    
    public init(mapView: ParentObject) {
        self.mapView = mapView
        super.init(parentObject: mapView, delegateProxy: RxMKMapViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register { RxMKMapViewDelegateProxy(mapView: $0) }
    }
}

extension Reactive where Base: MKMapView {
    public var delegate: DelegateProxy<MKMapView, MKMapViewDelegate> {
        return RxMKMapViewDelegateProxy.proxy(for: base)
    }
    
    public func setDelegate(_ delegate: MKMapViewDelegate) -> Disposable {
        return RxMKMapViewDelegateProxy.installForwardDelegate(
            delegate,
            retainDelegate: false,
            onProxyForObject: self.base
        )
    }
    
    var overlays: Binder<[MKOverlay]> {
        return Binder(self.base) { mapView, overlays in
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlays(overlays)
        }
    }
    
    public var regionDidChangeAnimated: ControlEvent<Bool> {
        let source = delegate
            .methodInvoked(#selector(MKMapViewDelegate.mapView(_:regionDidChangeAnimated:)))
            .map { parameters in
                return (parameters[1] as? Bool) ?? false
            }
        return ControlEvent(events: source)
    }
    
    public var location: Binder<CLLocationCoordinate2D> {
        return Binder(self.base) { map, location in
            let span = MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            map.region = MKCoordinateRegion(center: location, span: span)
        }
    }
}
