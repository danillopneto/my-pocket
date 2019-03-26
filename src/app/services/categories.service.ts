import { Injectable } from '@angular/core';
import { AngularFirestore, QueryFn } from '@angular/fire/firestore';
import { Category } from '../models/category.model';
import { throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';
import { BaseAngularService } from './base-angular.service';

@Injectable({
  providedIn: 'root'
})
export class CategoriesService extends BaseAngularService<Category> {  
  
  constructor(protected firestore: AngularFirestore) {
    super(firestore);
  }

  getCollectionReference(queryFn?: QueryFn) {
    return this.firestore.collection('danillopneto').doc("userSettings").collection<Category>("categories", queryFn);
  }
}
