import { Injectable } from '@angular/core';
import { AngularFirestore, QueryFn } from '@angular/fire/firestore';
import { throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';
import { BaseAngularService } from './base-angular.service';
import { PaymentMethod } from '../models/payment-method.model';

@Injectable({
  providedIn: 'root'
})
export class PaymentMethodsService extends BaseAngularService<PaymentMethod> {  
  
  constructor(protected firestore: AngularFirestore) {
    super(firestore);
  }

  getCollectionReference(queryFn?: QueryFn) {
    return this.firestore.collection('danillopneto')
              .doc("userSettings").collection<PaymentMethod>("paymentMethods", queryFn);
  }
}
