import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:go_router/go_router.dart';



import '../../../core/theme/app_theme.dart';

import '../../../routes/app_routes.dart';

import '../../controllers/password_reset_controller.dart';

import '../../widgets/auth_flow_scaffold.dart';



class ForgotPasswordScreen extends StatefulWidget {

  const ForgotPasswordScreen({super.key});



  @override

  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();

}



class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  late final PasswordResetController controller;



  @override

  void initState() {

    super.initState();

    controller = Get.put(PasswordResetController(), permanent: false);

  }



  @override

  Widget build(BuildContext context) {

    return AuthFlowScaffold(

      title: 'Forgot Password',

      subtitle: 'Enter your username and registered email to receive a reset OTP',

      child: Form(

        key: controller.forgotPasswordFormKey,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            TextFormField(

              controller: controller.usernameController,

              keyboardType: TextInputType.text,

              textInputAction: TextInputAction.next,

              autovalidateMode: AutovalidateMode.onUserInteraction,

              decoration: authInputDecoration(

                label: 'Username',

                icon: Icons.person_outline,

              ),

              validator: controller.validateUsername,

            ),

            const SizedBox(height: 16),

            TextFormField(

              controller: controller.emailController,

              keyboardType: TextInputType.emailAddress,

              textInputAction: TextInputAction.done,

              autovalidateMode: AutovalidateMode.onUserInteraction,

              decoration: authInputDecoration(

                label: 'Email Address',

                icon: Icons.email_outlined,

              ),

              validator: controller.validateEmail,

              onFieldSubmitted: (_) {

                if (!controller.isLoading.value) {

                  controller.handleForgotPassword(context);

                }

              },

            ),

            const SizedBox(height: 24),

            Obx(

              () => controller.errorMessage.value.isNotEmpty

                  ? authErrorBanner(controller.errorMessage.value)

                  : const SizedBox.shrink(),

            ),

            Obx(

              () => authPrimaryButton(

                isLoading: controller.isLoading.value,

                label: 'Send OTP',

                onPressed: controller.isLoading.value

                    ? null

                    : () => controller.handleForgotPassword(context),

              ),

            ),

            const SizedBox(height: 16),

            TextButton(

              onPressed: () => context.go(AppRoutes.login),

              child: Text(

                'Back to Sign In',

                style: TextStyle(

                  color: AppTheme.primaryColor,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}


