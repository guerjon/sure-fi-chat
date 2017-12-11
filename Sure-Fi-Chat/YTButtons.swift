//
//  YTButtons.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 11/27/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import UIKit

class YTRoundedButton: UIButton {
    
    required init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = self.frame.height / 2
        clipsToBounds = true
    }
}



