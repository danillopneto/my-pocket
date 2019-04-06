import { UtilityService } from './utility.service';
import { Injectable } from '@angular/core';
import { AngularFirestore, QueryFn } from '@angular/fire/firestore';
import { throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';
import { BaseAngularService } from './base-angular.service';
import { Place } from '../models/place.model';

@Injectable({
  providedIn: 'root'
})
export class PlacesService extends BaseAngularService<Place> {  
  
  constructor(protected firestore: AngularFirestore, protected util: UtilityService) {
    super(firestore, util);
  }

  getCollectionReference(queryFn?: QueryFn) {
    return this.firestore.collection<Place>("places", queryFn);
  }
}
