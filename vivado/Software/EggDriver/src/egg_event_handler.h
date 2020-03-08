//
// Created by benjaminkulnik on 3/8/20.
//

#ifndef EGGNETDRIVER_EGG_EVENT_HANDLER_H
#define EGGNETDRIVER_EGG_EVENT_HANDLER_H

#include <iostream>

class Callback {
public:
    virtual ~Callback() { std::cout << "Callback::~Callback()" << std:: endl; }
    virtual void run() { std::cout << "Callback::run()" << std::endl; }
};

class Caller {
private:
    Callback *_callback;
public:
    Caller(): _callback(0) {}
    ~Caller() { delCallback(); }
    void delCallback() { delete _callback; _callback = 0; }
    void setCallback(Callback *cb) { delCallback(); _callback = cb; }
    void call() { if (_callback) _callback->run(); }
};


#endif //EGGNETDRIVER_EGG_EVENT_HANDLER_H
