// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_passthrough.h for the primary calling header

#ifndef VERILATED_VTB_PASSTHROUGH___024ROOT_H_
#define VERILATED_VTB_PASSTHROUGH___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtb_passthrough__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_passthrough___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_passthrough__DOT__clk;
    CData/*0:0*/ tb_passthrough__DOT__rst_n;
    CData/*7:0*/ tb_passthrough__DOT__i_8bit;
    CData/*7:0*/ tb_passthrough__DOT__o_8bit;
    CData/*0:0*/ __Vdlyvval__tb_passthrough__DOT__clk__v0;
    CData/*0:0*/ __Vdlyvset__tb_passthrough__DOT__clk__v0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_passthrough__DOT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_passthrough__DOT__rst_n__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VlDelayScheduler __VdlySched;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtb_passthrough__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtb_passthrough___024root(Vtb_passthrough__Syms* symsp, const char* v__name);
    ~Vtb_passthrough___024root();
    VL_UNCOPYABLE(Vtb_passthrough___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
