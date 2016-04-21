//
//  Node.mm
//  NNPlayground
//
//  Created by 杨培文 on 16/4/18.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#include "Node.h"

double Node::updateOutput() {
    // Stores total input into the node.
    totalInput = bias;
    for (int j = 0; j < inputLinks.size(); j++) {
        auto link = inputLinks[j];
        totalInput += link->weight * link->source->output;
    }
    output = activation.output(totalInput);
    return output;
}
