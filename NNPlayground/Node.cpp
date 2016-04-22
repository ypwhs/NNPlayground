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
    for (int i = 0; i < inputLinks.size(); i++) {
        auto link = inputLinks[i];
        totalInput += link->weight * link->source->output;
    }
    output = activation.output(totalInput);
    return output;
}

Node::~Node(){
    //delete every link
    for (int i = 0; i < inputLinks.size(); i++) {
        free(inputLinks[i]);
    }
}