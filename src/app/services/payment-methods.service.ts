import { Injectable } from '@angular/core';
import { AngularFirestore, QueryFn } from '@angular/fire/firestore';
import { throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';
import { BaseAngularService } from './base-angular.service';
import { PaymentMethod } from '../models/payment-method.model';
import { UtilityService } from './utility.service';

@Injectable({
  providedIn: 'root'
})
export class PaymentMethodsService extends BaseAngularService<PaymentMethod> {  
  
  constructor(protected firestore: AngularFirestore, protected util: UtilityService) {
    super(firestore, util);
  }

  getCollectionReference(queryFn?: QueryFn) {
    return this.firestore.collection<PaymentMethod>("paymentMethods", queryFn);
  }
}
