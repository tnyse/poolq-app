import 'package:flutter/material.dart';
import '../../../Constants/value.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Widget/reuse.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/Module/Screen/Auth/Signup.dart';
import 'package:poolqapp/Module/Screen/Home/landingPage.dart';


class ForgetWidget extends StatefulWidget {
  const ForgetWidget({Key? key}) : super(key: key);

  @override
  _ForgetWidgetState createState() => _ForgetWidgetState();
}

class _ForgetWidgetState extends State<ForgetWidget> {
  // late ForgetModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController? emailAddressController;

  @override
  void initState() {
    super.initState();
    // _model = createModel(context, () => ForgetModel());

    emailAddressController ??= TextEditingController();
  }

  @override
  void dispose() {
    // _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // context.watch<FFAppState>();
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: false);

    return Scaffold(
      key: scaffoldKey,
      // backgroundColor: primary,
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(100),
      //   child: AppBar(
      //     backgroundColor: Colors.transparent,
      //     automaticallyImplyLeading: false,
      //     title: Column(
      //       mainAxisSize: MainAxisSize.max,
      //       mainAxisAlignment: MainAxisAlignment.end,
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         Padding(
      //           padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 8),
      //           child: Row(
      //             mainAxisSize: MainAxisSize.max,
      //             children: [
      //               // Padding(
      //               //   padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
      //               //   child: FlutterFlowIconButton(
      //               //     borderColor: Colors.transparent,
      //               //     borderRadius: 30,
      //               //     borderWidth: 1,
      //               //     buttonSize: 50,
      //               //     icon: Icon(
      //               //       Icons.arrow_back_rounded,
      //               //       color: FlutterFlowTheme.of(context).primaryText,
      //               //       size: 24,
      //               //     ),
      //               //     onPressed: () async {
      //               //       Navigator.pop(context);
      //               //     },
      //               //   ),
      //               // ),
      //               Padding(
      //                 padding: EdgeInsetsDirectional.fromSTEB(4, 0, 0, 0),
      //                 child: Text(
      //                   'Back',
      //                   style:
      //                  TextStyle(
      //                     fontFamily: 'Poppins',
      //                     fontSize: 16,
      //                      color: Colors.black
      //                   ),
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //         Padding(
      //           padding: EdgeInsetsDirectional.fromSTEB(24, 0, 0, 0),
      //           child: Text(
      //             'Forgot Password',
      //             style:TextStyle(
      //               fontFamily: 'Poppins',
      //               fontSize: 32,
      //               color: Colors.black
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //     actions: [],
      //     centerTitle: true,
      //     elevation: 0,
      //   ),
      // ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20, 50, 20, 8),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(4, 4, 4, 4),
                    child: Text(
                      'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
                      // style: FlutterFlowTheme.of(context).bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Padding(
          //   padding: EdgeInsetsDirectional.fromSTEB(24, 4, 24, 30),
          //   child: Container(
          //     width: double.infinity,
          //     height: 65,
          //     decoration: BoxDecoration(
          //       color: secondaryBackground,
          //       boxShadow: [
          //         BoxShadow(
          //           blurRadius: 5,
          //           color: Color(0x4D101213),
          //           offset: Offset(0, 2),
          //         )
          //       ],
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: TextFormField(
          //       controller: emailAddressController,
          //       obscureText: false,
          //       decoration: InputDecoration(
          //         labelText: 'Your email address...',
          //         // labelStyle: FlutterFlowTheme.of(context).bodySmall,
          //         hintText: 'Enter your email...',
          //         hintStyle: TextStyle(
          //           fontFamily: 'Lexend Deca',
          //           color: Color(0xFF57636C),
          //           fontSize: 14,
          //           fontWeight: FontWeight.normal,
          //         ),
          //         enabledBorder: OutlineInputBorder(
          //           borderSide: BorderSide(
          //             color: Color(0x00000000),
          //             width: 0,
          //           ),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         focusedBorder: OutlineInputBorder(
          //           borderSide: BorderSide(
          //             color: Color(0x00000000),
          //             width: 0,
          //           ),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         errorBorder: OutlineInputBorder(
          //           borderSide: BorderSide(
          //             color: Color(0x00000000),
          //             width: 0,
          //           ),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         focusedErrorBorder: OutlineInputBorder(
          //           borderSide: BorderSide(
          //             color: Color(0x00000000),
          //             width: 0,
          //           ),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         filled: true,
          //         fillColor: secondaryBackground,
          //         contentPadding:
          //         EdgeInsetsDirectional.fromSTEB(24, 24, 20, 24),
          //       ),
          //       // style: FlutterFlowTheme.of(context).bodyMedium,
          //       maxLines: 1,
          //       // validator:
          //       // _model.emailAddressControllerValidator.asValidator(context),
          //     ),
          //   ),
          // ),
          Align(
            alignment: AlignmentDirectional(0, 0),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 16),
              child: SizedBox(
                width: 180,
                height: 40,
                child: TextButton(
                  onPressed: () async {
                    // if (emailAddressController!.text.isEmpty) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(
                    //       content: Text(
                    //         'Email required!',
                    //       ),
                    //     ),
                    //   );
                    //   return;
                    // }
                    circularCustom(context);
                    await authProvider.verifyEmail(
                      // emailAddressController!.text,
                      context,
                    );
                  },
                  child: Text('Verify', style: TextStyle(color: Colors.white)),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    ),
                    backgroundColor: MaterialStateProperty.all(primary),
                    foregroundColor: MaterialStateProperty.all(primary),
                    textStyle: MaterialStateProperty.all(TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    )),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    )),
                    elevation: MaterialStateProperty.all(3),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional(0, 0),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 16),
              child: SizedBox(
                width: 180,
                height: 40,
                child: TextButton(
                  onPressed: () async {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterWidget(),
                      ),
                      (r) => false,
                    );
                  },
                  child: Text('Continue',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    ),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.transparent),
                    foregroundColor: MaterialStateProperty.all(primary),
                    textStyle: MaterialStateProperty.all(TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    )),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    )),
                    elevation: MaterialStateProperty.all(0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
