/*
 * Presents the ELAN touchpad of lenovo-tablet to Linux on boots where the
 * BIOS's own touchpad probe at POST failed. See nix/touchpad.nix for the
 * decision comment. Everything here mirrors \_SB.I2CD.TPD0 from the
 * QXCN20WW DSDT (same _HID, same I2C address and bus, same GPIO interrupt,
 * same _DSM answer) except _STA, which is the inverse of the original:
 * present exactly when the firmware did not present TPD0 itself.
 */
DefinitionBlock ("", "SSDT", 2, "JAPPIE", "TPDLNX", 0x00000001)
{
    External (\TPTY, FieldUnitObj)
    External (\_SB.I2CD, DeviceObj)

    Scope (\_SB.I2CD)
    {
        Device (TPDL)
        {
            Name (_HID, "ELAN06FA")
            Name (_CID, "PNP0C50")
            Name (_UID, 0x15)

            Method (_STA, 0, NotSerialized)
            {
                If ((TPTY == One))
                {
                    Return (Zero)
                }

                Return (0x0F)
            }

            Name (_CRS, ResourceTemplate ()
            {
                I2cSerialBus (0x0015, ControllerInitiated, 0x00061A80,
                    AddressingMode7Bit, "\\_SB.I2CD",
                    0x00, ResourceConsumer, , )
                GpioInt (Level, ActiveLow, ExclusiveAndWake, PullUp, 0x0000,
                    "\\_SB.GPIO", 0x00, ResourceConsumer, , )
                    {
                        0x0009
                    }
            })

            Method (_DSM, 4, Serialized)
            {
                If ((Arg0 == ToUUID ("3cdff6f7-4267-4555-ad05-b30a3d8938de")))
                {
                    If ((Arg2 == Zero))
                    {
                        If ((Arg1 == One))
                        {
                            Return (Buffer (One) { 0x03 })
                        }

                        Return (Buffer (One) { 0x00 })
                    }

                    If ((Arg2 == One))
                    {
                        Return (One)
                    }
                }

                Return (Buffer (One) { 0x00 })
            }
        }
    }
}
