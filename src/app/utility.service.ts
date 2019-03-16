import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class UtilityService {

  constructor() { }

  prepareComponents() {
    M.CharacterCounter.init(document.querySelectorAll('.character-counter'));
  }
}
