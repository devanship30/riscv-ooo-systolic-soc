// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe_tb.h for the primary calling header

#include "Vpe_tb__pch.h"
#include "Vpe_tb__Syms.h"
#include "Vpe_tb___024root.h"

void Vpe_tb___024root___ctor_var_reset(Vpe_tb___024root* vlSelf);

Vpe_tb___024root::Vpe_tb___024root(Vpe_tb__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vpe_tb___024root___ctor_var_reset(this);
}

void Vpe_tb___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vpe_tb___024root::~Vpe_tb___024root() {
}
