//@dart=2.12
import 'package:little_light/exceptions/littlelight.exception.base.dart';

class InvalidMembershipException extends LittleLightBaseException {
  InvalidMembershipException(sourceError) : super(sourceError);
}
