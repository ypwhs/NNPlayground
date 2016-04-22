//
//  Network.m
//  NN
//
//  Created by 杨培文 on 16/4/19.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import "Network.h"

Network::Network(int networkShape[], int numLayers, ActivationFunction activation, RegularizationFunction regularzation) {
    //    int numLayers = (int)networkShape.size();
    Activation act;
    Regularization reg;
    switch (activation) {
        case aReLU:
            act.output = ReLU;
            act.der = derReLU;
            break;
        case aTanh:
            act.output = Tanh;
            act.der = derTanh;
            break;
        case aSigmoid:
            act.output = Sigmoid;
            act.der = derSigmoid;
            break;
        case aLinear:
            act.output = Linear;
            act.der = derLinear;
            break;
        default:
            break;
    }
    
    switch (regularzation) {
        case rNone:
            reg.output = None;
            reg.der = None;
            break;
        case rL1:
            reg.output = L1;
            reg.der = derL1;
            break;
        case rL2:
            reg.output = L2;
            reg.der = derL2;
            break;
        default:
            break;
    }
    /** List of layers, with each layer being a list of nodes. */
    for (int layerIdx = 0; layerIdx < numLayers; layerIdx++) {
        vector<Node*>* currentLayer = new vector<Node*>();
        int numNodes = networkShape[layerIdx];
        for (int i = 0; i < numNodes; i++) {
            auto node = new Node(act);
            node->layer = layerIdx + 1; //tag this node
            node->id = i + 1;
            if (layerIdx >= 1) {
                // Add links from nodes in the previous layer to this node.
                for (int j = 0; j < network[layerIdx - 1]->size(); j++) {
                    Node * prevNode = (*network[layerIdx - 1])[j];
                    auto link = new Link(prevNode, node, reg);
                    prevNode->outputs.push_back(link);
                    node->inputLinks.push_back(link);
                }
            }
            currentLayer->push_back(node);
        }
        network.push_back(currentLayer);
    }
}

double Network::forwardProp(double inputs[], int inputSize) {
    vector<Node*> &inputLayer = *network[0];
    auto inputLayerSize = inputLayer.size();
    if (inputSize != inputLayerSize) {
        printf("The number of inputs must match the number of nodes in the input layer!\n");
        return -1;
    }
    
    // Update the input layer.
    for (int i = 0; i < inputLayerSize; i++) {
        inputLayer[i]->output = inputs[i];
    }
    
    for (int layerIdx = 1; layerIdx < network.size(); layerIdx++) {
        // Update all the nodes in this layer.
        vector<Node*> &currentLayer = *network[layerIdx];
        auto currentLayerSize = currentLayer.size();
        for (int i = 0; i < currentLayerSize; i++) {
            currentLayer[i]->updateOutput();
        }
    }
    return (*network[network.size() - 1])[0]->output;
}

void Network::backProp(double target) {
    // The output node is a special case. We use the user-defined error
    // function for the derivative.
    auto networkSize = network.size();
    vector<Node*> &lastLayer = *network[networkSize - 1];
    auto outputNode = lastLayer[0];
    outputNode->outputDer = outputNode->output - target;
    
    // Go through the layers backwards.
    for (auto layerIdx = networkSize - 1; layerIdx >= 1; layerIdx--) {
        vector<Node*> &currentLayer = *network[layerIdx];
        // Compute the error derivative of each node with respect to:
        // 1) its total input
        // 2) each of its input weights.
        auto currentLayerSize = currentLayer.size();
        for (int i = 0; i < currentLayerSize; i++) {
            auto node = currentLayer[i];
            node->inputDer = node->outputDer * node->activation.der(node->totalInput);
            node->accInputDer += node->inputDer;
            node->numAccumulatedDers++;
        }
        
        // Error derivative with respect to each weight coming into the node.
        for (int i = 0; i < currentLayerSize; i++) {
            auto node = currentLayer[i];
            auto inputLinks = node->inputLinks.size();
            for (int j = 0; j < inputLinks; j++) {
                auto link = node->inputLinks[j];
                link->errorDer = node->inputDer * link->source->output;
                link->accErrorDer += link->errorDer;
                link->numAccumulatedDers++;
            }
        }
        if (layerIdx == 1) {
            continue;
        }
        
        vector<Node*> &prevLayer = *network[layerIdx - 1];
        int prevLayerSize = (int)prevLayer.size();
        for (int i = 0; i < prevLayerSize; i++) {
            auto node = prevLayer[i];
            // Compute the error derivative with respect to each node's output.
            node->outputDer = 0;
            auto outputs = node->outputs.size();
            for (int j = 0; j < outputs; j++) {
                auto output = node->outputs[j];
                node->outputDer += output->weight * output->dest->inputDer;
            }
        }
    }
}

void Network::updateWeights(double learningRate, double regularizationRate) {
    auto networkSize = network.size();
    for (int layerIdx = 1; layerIdx < networkSize; layerIdx++) {
        vector<Node*> &currentLayer = *network[layerIdx];
        auto currentLayerSize = currentLayer.size();
        for (int i = 0; i < currentLayerSize; i++) {
            auto node = currentLayer[i];
            // Update the node's bias.
            if (node->numAccumulatedDers > 0) {
                node->bias -= learningRate * node->accInputDer / node->numAccumulatedDers;
                node->accInputDer = 0;
                node->numAccumulatedDers = 0;
            }
            // Update the weights coming into this node.
            auto inputLinks = node->inputLinks.size();
            for (int j = 0; j < inputLinks; j++) {
                auto link = node->inputLinks[j];
                auto regulDer = link->regularization.der(link->weight);
                if (link->numAccumulatedDers > 0) {
                    link->weight -= (learningRate / link->numAccumulatedDers) *
                    (link->accErrorDer + regularizationRate * regulDer);
                    link->accErrorDer = 0;
                    link->numAccumulatedDers = 0;
                }
            }
        }
    }
}

void Network::forEachNode(bool ignoreInputs, void (*accessor)(Node*) ){
    for (int layerIdx = ignoreInputs ? 1 : 0; layerIdx < network.size(); layerIdx++) {
        vector<Node*> & currentLayer = *network[layerIdx];
        for (int i = 0; i < currentLayer.size(); i++) {
            accessor(currentLayer[i]);
        }
    }
}

Node* Network::getOutputNode(){
    return (*network[network.size()-1])[0];
}
