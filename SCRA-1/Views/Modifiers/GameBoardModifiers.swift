//
//  GameBoardModifiers.swift
//  SCRA-1
//
//  Created by KeefCheif on 3/7/22.
//

import SwiftUI

struct OldBoardModifiers: ViewModifier {
    
    var geo: GeometryProxy
    
    @Binding var board_details: BoardDetails
    
    var default_view_position: CGPoint {
        return CGPoint(x: self.geo.size.width/2, y: self.geo.size.width/2)
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(self.board_details.zoom ? 2.0 : 1.0)
            .position(self.board_details.zoom ? self.board_details.view_position : self.default_view_position)
            .offset(x: self.board_details.offset.x, y: self.board_details.offset.y)
            .animation(.easeIn, value: self.board_details.zoom)
        
            // Drag gesture for moving the zoomed in board around
            .gesture(DragGesture().onChanged { drag in
                if (self.board_details.zoom) {
                    let translation: CGSize = self.boundDragTranslation(drag: drag.translation, limit: geo.size.width)
                    self.board_details.offset = CGPoint(x: translation.width, y: translation.height)
                }
            }.onEnded { drag in
                if (self.board_details.zoom) {
                    self.board_details.offset = .zero
                    let translation: CGSize = self.boundDragTranslation(drag: drag.translation, limit: geo.size.width)
                    self.board_details.view_position = CGPoint(x: translation.width + self.board_details.view_position.x, y: translation.height + self.board_details.view_position.y)
                    
                    self.board_details.coordinate_position = CGPoint(x: self.board_details.coordinate_position.x - (translation.width/2), y: self.board_details.coordinate_position.y - (translation.height/2))
                }
            })
            
            // Double tap gesture for zooming into and out of the board
            .gesture(
                TapGesture(count: 2).onEnded {
                    
                    self.board_details.zoom.toggle()
                    
                    if !self.board_details.zoom {
                        self.board_details.offset = .zero
                    }
                
                }.simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .named("board")).onEnded { double_tap in
                    
                    if !self.board_details.zoom {
                        // Zoom into the location that the user double taps
                        let translation: CGPoint = self.boundedZoomTranslation(zoom_location: double_tap.location)
                        let movement: CGPoint = CGPoint(x: (geo.size.width/2 - translation.x) * 2, y: (geo.size.width/2 - translation.y) * 2)
                        
                        self.board_details.view_position = CGPoint(x: geo.size.width/2 + movement.x, y: geo.size.width/2 + movement.y)
                        self.board_details.coordinate_position = translation
                    }
                    
                })
            )
            .clipped()
        
    }
    
    private func boundDragTranslation(drag: CGSize, limit: CGFloat) -> CGSize {
        // This function makes sure that the length of the drag will not cause the board to exceed its border
        // It either returns the regular drag size or the maximum drag size where only the board is shown still
        
        var translation: CGSize = drag
        
        if (drag.width + self.board_details.view_position.x > limit) {
            translation.width = limit - self.board_details.view_position.x
        } else if (drag.width + self.board_details.view_position.x < 0) {
            translation.width = 0 - self.board_details.view_position.x
        }
        
        if (drag.height + self.board_details.view_position.y > limit) {
            translation.height = limit - self.board_details.view_position.y
        } else if (drag.height + self.board_details.view_position.y < 0) {
            translation.height = 0 - self.board_details.view_position.y
        }
        
        return translation
    }
    

    private func boundedZoomTranslation(zoom_location: CGPoint) -> CGPoint {
        // This function makes sure that location the user double taps is not too close to the border of the board
        // It either returns the location the user tapped or the nearest location where only the board will be shown when zoomed in
        
        var tranlsation: CGPoint = zoom_location
        
        if (zoom_location.x > self.geo.size.width * (3/4)) {
            tranlsation.x = self.geo.size.width * (3/4)
        } else if (zoom_location.x < self.geo.size.width/4) {
            tranlsation.x = self.geo.size.width/4
        }
        
        if (zoom_location.y > self.geo.size.width * (3/4)) {
            tranlsation.y = self.geo.size.width * (3/4)
        } else if (zoom_location.y < self.geo.size.width/4) {
            tranlsation.y = self.geo.size.width/4
        }
        
        return tranlsation
        
    }
    
}

struct BoardModifier: ViewModifier {
    
    var geo: GeometryProxy
    
    @Binding var board_details: BoardDetails
    
    var default_view_position: CGPoint {
        return CGPoint(x: self.geo.size.width/2, y: self.geo.size.width/2)
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(self.board_details.zoom ? 2.0 : 1.0)
            .position(self.board_details.zoom ? self.board_details.view_position : self.default_view_position)
            .offset(x: self.board_details.offset.x, y: self.board_details.offset.y)
            .animation(.easeInOut, value: self.board_details.zoom)
        
            .gesture(DragGesture().onChanged { drag in
                if self.board_details.zoom {
                    let translation: CGSize = self.boundDragTranslation(drag: drag.translation, limit: self.geo.size.width)
                    self.board_details.offset = CGPoint(x: translation.width, y: translation.height)
                }
            }.onEnded { drag in
                if self.board_details.zoom {
                    self.board_details.offset = .zero
                    
                    let translation: CGSize = self.boundDragTranslation(drag: drag.translation, limit: self.geo.size.width)
                    self.board_details.view_position = CGPoint(x: translation.width + self.board_details.view_position.x, y: translation.height + self.board_details.view_position.y)
                    self.board_details.coordinate_position = CGPoint(x: self.board_details.coordinate_position.x - (translation.width/2), y: self.board_details.coordinate_position.y - (translation.height/2))
                }
            })
        
            .gesture(TapGesture(count: 2).onEnded {
                self.board_details.zoom.toggle()
                
                if !self.board_details.zoom {
                    self.board_details.offset = .zero
                }
            }.simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .named("board_rack")).onEnded { double_tap in
                
                if !self.board_details.zoom {
                    // Zoom into the location that the user double taps
                    let translation: CGPoint = self.boundedZoomTranslation(zoom_location: double_tap.location)
                    let movement: CGPoint = CGPoint(x: (geo.size.width/2 - translation.x) * 2, y: (geo.size.width/2 - translation.y) * 2)
                    
                    self.board_details.view_position = CGPoint(x: geo.size.width/2 + movement.x, y: geo.size.width/2 + movement.y)
                    self.board_details.coordinate_position = translation
                }
            }))
            .clipped()
    }
    
    private func boundDragTranslation(drag: CGSize, limit: CGFloat) -> CGSize {
        // This function makes sure that the length of the drag will not cause the board to exceed its border
        // It either returns the regular drag size or the maximum drag size where only the board is shown still
        
        var translation: CGSize = drag
        
        if (drag.width + self.board_details.view_position.x > limit) {
            translation.width = limit - self.board_details.view_position.x
        } else if (drag.width + self.board_details.view_position.x < 0) {
            translation.width = 0 - self.board_details.view_position.x
        }
        
        if (drag.height + self.board_details.view_position.y > limit) {
            translation.height = limit - self.board_details.view_position.y
        } else if (drag.height + self.board_details.view_position.y < 0) {
            translation.height = 0 - self.board_details.view_position.y
        }
        
        return translation
    }
    
    private func boundedZoomTranslation(zoom_location: CGPoint) -> CGPoint {
        // This function makes sure that location the user double taps is not too close to the border of the board
        // It either returns the location the user tapped or the nearest location where only the board will be shown when zoomed in
        
        var tranlsation: CGPoint = zoom_location
        
        if (zoom_location.x > self.geo.size.width * (3/4)) {
            tranlsation.x = self.geo.size.width * (3/4)
        } else if (zoom_location.x < self.geo.size.width/4) {
            tranlsation.x = self.geo.size.width/4
        }
        
        if (zoom_location.y > self.geo.size.width * (3/4)) {
            tranlsation.y = self.geo.size.width * (3/4)
        } else if (zoom_location.y < self.geo.size.width/4) {
            tranlsation.y = self.geo.size.width/4
        }
        
        return tranlsation
        
    }
}
